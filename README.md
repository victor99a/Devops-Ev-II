# Servicio Base para Evaluacion de CI/CD

Servicio REST con **Arquitectura Hexagonal (Puertos y Adaptadores)** desarrollado en **Java 17** con **Spring Boot 3.3.5**, persistencia en **PostgreSQL 15**, contenerizado con Docker multi-stage y orquestado via GitHub Actions con pipeline completo de CI/CD que incluye calidad de codigo, escaneo de seguridad y despliegue automatizado validado.

---

## 1. Arquitectura del Proyecto

```
demo-ms/
├── .github/
│   ├── workflows/ci.yml              # Pipeline CI/CD (GitHub Actions)
│   └── dependabot.yml                # Actualizacion automatica de dependencias
├── .snyk                             # Politica de exclusion de Snyk
├── Dockerfile                        # Multi-stage: build (Maven/JDK 21) + run (JRE Alpine + curl)
├── docker-compose.yml                # Orquestacion local: app + db (PostgreSQL 15)
├── pom.xml                           # Maven + Spring Boot 3.3.5 + JPA + PostgreSQL + JaCoCo
├── src/main/java/com/example/demo/
│   ├── DemoApplication.java          # Entry point
│   ├── domain/
│   │   ├── model/
│   │   │   └── Greeting.java         # Entidad de dominio pura (record, sin anotaciones)
│   │   └── port/
│   │       ├── inbound/
│   │       │   ├── CreateGreetingUseCase.java   # Puerto: crear saludo
│   │       │   └── LifecycleUseCase.java        # Puerto: listar/buscar saludos
│   │       └── outbound/
│   │           └── GreetingRepositoryPort.java  # Puerto: contrato de persistencia
│   ├── application/
│   │   └── service/
│   │       └── GreetingServiceImpl.java         # Implementacion de casos de uso (sin dependencias JPA)
│   └── infrastructure/
│       ├── inbound/
│       │   └── controller/
│       │       └── GreetingController.java      # Adaptador REST (3 endpoints)
│       └── outbound/
│           └── database/
│               ├── GreetingEntity.java          # Entidad JPA (solo infraestructura)
│               ├── SpringGreetingRepository.java # Interfaz Spring Data JPA
│               └── GreetingRepositoryAdapter.java # Adaptador: implementa GreetingRepositoryPort
├── src/main/resources/
│   └── application.yml                # Configuracion PostgreSQL + Actuator
└── src/test/java/com/example/demo/
    ├── application/service/
    │   └── GreetingServiceImplTest.java             # Unit test (Mockito, 8 tests)
    ├── infrastructure/inbound/controller/
    │   └── GreetingControllerTest.java              # @WebMvcTest + MockMvc (6 tests)
    └── infrastructure/outbound/database/
        └── GreetingRepositoryAdapterTest.java       # Unit test (Mockito, 5 tests)
```

### Principios de Arquitectura Hexagonal

- **Dependencias apuntan hacia adentro**: `infrastructure → application → domain`
- **El dominio no conoce frameworks**: ni Spring, ni JPA, ni anotaciones externas
- **Puertos (interfaces)** en el dominio definen contratos; **Adaptadores** en infraestructura los implementan
- **Mapping** entre entidad de dominio (`Greeting`) y entidad JPA (`GreetingEntity`) ocurre exclusivamente en el adaptador de salida

---

## 2. Arquitectura del Pipeline CI/CD

```
                  PUSH / PR a main
                        │
                 ┌──────▼──────┐
                 │ Build, Test │  mvn clean verify
                 │  & Coverage │  JUnit 5 (19 tests)
                 │   (JaCoCo)  │  JaCoCo gate >= 80%
                 └──────┬──────┘
                        │
                 ┌──────▼──────┐
                 │  Security   │  Snyk scan
                 │  (Snyk)     │  --severity-threshold=high
                 │             │  BREAK BUILD on HIGH/CRITICAL
                 └──────┬──────┘
                        │
                 ┌──────▼──────┐
                 │  Deploy &   │  docker compose up -d
                 │  Validate   │  curl /actuator/health
                 │             │  curl /api/v1/greetings
                 │             │  docker inspect (health status)
                 │             │  docker compose down
                 └─────────────┘
```

### Etapas y trazabilidad

| Etapa | Herramienta | Artefacto generado | Validacion |
|---|---|---|---|
| **Build & Test** | Maven, JUnit 5, JaCoCo | `surefire-reports`, `jacoco-report`, JAR | Quality Gate 80% line coverage |
| **Security** | Snyk | Reporte de vulnerabilidades en consola | Falla si encuentra High o Critical |
| **Deploy** | Docker Compose, curl | `docker build` cache | HTTP 200 en `/actuator/health` y `/api/v1/greetings` + `docker inspect` healthy |
| **Dependabot** | GitHub Dependabot | PRs automaticas semanales | Maven + GitHub Actions |

### Reglas de calidad (Quality Gates)

- **JaCoCo**: `mvn verify` falla si la cobertura de lineas es menor a **80%** (excluye `DemoApplication`, `domain/model/*`, `GreetingEntity` y `SpringGreetingRepository` por ser boilerplate)
- **Snyk**: el pipeline falla si se detecta al menos una vulnerabilidad de severidad **High** o **Critical**
- **JUnit**: 19 pruebas que validan controlador (MockMvc), servicio (unit tests puros) y adaptador (mapping)
- **Endpoint validation**: curl con reintentos + healthcheck de Docker

---

## 3. Contenerizacion

### Dockerfile (multi-stage)

| Etapa | Imagen | Proposito |
|---|---|---|
| `build` | `maven:3.9-eclipse-temurin-21-alpine` | Compilar JAR |
| `run` | `eclipse-temurin:21-jre-alpine` | Ejecutar con usuario no-root (`appuser`) + curl |

- **HEALTHCHECK** usa `curl` contra `/actuator/health` en puerto 8080 (intervalo 30s, timeout 5s, 3 reintentos)
- Usuario no-root (`appuser`) por seguridad

### docker-compose.yml

```yaml
services:
  db:             # PostgreSQL 15 Alpine
    healthcheck:  # pg_isready
    restart: unless-stopped

  app:            # demo-ms
    depends_on: db (condition: service_healthy)
    restart: unless-stopped
    deploy:
      resources:
        limits:   { cpus: 1.0, memory: 512M }
        reservations: { cpus: 0.5, memory: 256M }
```

---

## 4. Base de Datos

| Variable | Default | Descripcion |
|---|---|---|
| `DB_HOST` | `localhost` | Host de PostgreSQL |
| `DB_PORT` | `5432` | Puerto de PostgreSQL |
| `DB_NAME` | `demo` | Nombre de la base de datos |
| `DB_USER` | `postgres` | Usuario de PostgreSQL |
| `DB_PASS` | `postgres` | Password de PostgreSQL |

Spring Boot JPA usa `ddl-auto: update` para crear/actualizar automaticamente la tabla `greetings`.

---

## 5. Monitoreo de Dependencias

El archivo `.github/dependabot.yml` configura actualizaciones semanales (lunes 09:00 America/Santiago):

- **maven**: `pom.xml` — max 10 PRs abiertas
- **github-actions**: todos los workflows — max 5 PRs abiertas

---

## 6. Configuracion de Seguridad (IE3)

### Snyk

El job `security` ejecuta `snyk test --severity-threshold=high` sobre el proyecto Maven. Requiere el secreto `SNYK_TOKEN` configurado en el repositorio:

```
Settings > Secrets and variables > Actions > New repository secret
Name:  SNYK_TOKEN
Value: <token obtenido de https://app.snyk.io/account>
```

La politica `.snyk` excluye directorios de build (`target/`) y reporta solo severidades High y Critical.

---

## 7. Endpoints

| Metodo | Path | Descripcion | Respuesta |
|---|---|---|---|
| `GET` | `/api/v1/greetings` | Listar todos los saludos | 200, array de greetings |
| `POST` | `/api/v1/greetings?name=DevOps` | Crear nuevo saludo | 201, greeting creado |
| `GET` | `/api/v1/greetings/{id}` | Buscar saludo por ID | 200 / 404 |
| `GET` | `/actuator/health` | Health check (Actuator) | 200, `{"status":"UP"}` |

Ejemplo de respuesta `POST /api/v1/greetings?name=DevOps`:

```json
{
  "id": 1,
  "name": "DevOps",
  "message": "Hello, DevOps!",
  "timestamp": "2026-05-29T21:29:28.123Z"
}
```

---

## 8. Ejecucion local

```bash
# Build + tests + coverage
mvn clean verify

# Levantar con Docker Compose (app + PostgreSQL)
docker compose up -d

# Probar endpoints
curl http://localhost:8080/api/v1/greetings
curl -X POST "http://localhost:8080/api/v1/greetings?name=Duoc"
curl http://localhost:8080/api/v1/greetings/1
curl http://localhost:8080/actuator/health

# Detener
docker compose down
```

---

## 9. Declaracion de Uso de IA

De acuerdo con las politicas de integridad academica de Duoc UC y la guia de uso de inteligencia artificial disponible en [https://bibliotecas.duoc.cl/ia](https://bibliotecas.duoc.cl/ia), el equipo declara que la herramienta de inteligencia artificial **OpenCode (Anthropic Claude via deepseek-v4-pro)** fue utilizada en Mayo 2026 para los siguientes propositos:

| Herramienta | Version / Modelo | Proposito especifico | Entregable impactado |
|---|---|---|---|
| **OpenCode (Anthropic Claude via deepseek-v4-pro)** | Mayo 2026 | Diseno e implementacion de la arquitectura hexagonal (Puertos y Adaptadores): estructura de paquetes, interfaces de puertos, adaptadores REST y JPA, mapping entre capas. | `domain/`, `application/`, `infrastructure/` |
| **OpenCode (Anthropic Claude via deepseek-v4-pro)** | Mayo 2026 | Generacion de pruebas unitarias con JUnit 5 y Mockito para la capa de aplicacion, controlador y adaptador de persistencia (19 tests). | `src/test/` |
| **OpenCode (Anthropic Claude via deepseek-v4-pro)** | Mayo 2026 | Redaccion, formato y estructuracion de la documentacion del proyecto (`README.md`). | `README.md` |

### Metodo de validacion

Todo el codigo generado con asistencia de IA fue revisado y validado mediante:
- Ejecucion de `mvn clean verify` verificando que los 19 tests pasan y el Quality Gate de JaCoCo (80%) se cumple
- Revision manual de la arquitectura hexagonal para asegurar que las dependencias apuntan hacia adentro y el dominio no tiene acoplamiento a frameworks
- Verificacion de que el `docker-compose.yml` levanta correctamente los servicios `db` y `app` con healthchecks funcionales

### Compromiso etico

El equipo certifica que comprende el funcionamiento de cada componente entregado y asume responsabilidad plena sobre el producto final.

Declaracion firmada por:
- Victor Barrera Jara — 20968480-2
- [Nombre integrante 2] — [RUT]

---

## 10. ⚠️ PLACEHOLDER — Reflexiones Individuales Obligatorias

> **[COMPLETAR POR CADA INTEGRANTE]**
>
> ### Integrante 1: Victor Barrera Jara — 20968480-2
>
> **Reflexion sobre CI/CD:**
> Se aprendio que la integracion continua automatiza la validacion de cada cambio (build + tests + coverage), detectando errores en minutos en vez de dias. El pipeline bloquea cualquier PR o commit que no cumpla los quality gates: si la cobertura baja del 80% o Snyk encuentra vulnerabilidades High/Critical, el merge se rechaza automaticamente, forzando a corregir antes de integrar.
>
> **Reflexion sobre calidad y seguridad:**
> JaCoCo impone un piso minimo del 80% de cobertura de linea — si no se alcanza, `mvn verify` falla y el pipeline frena el merge. Snyk escanea dependencias en cada build y tambien rompe el pipeline si detecta severidades High/Critical. Ambas herramientas actuan como guardianes que impiden que codigo con baja calidad o riesgos de seguridad llegue a produccion.
>
> **Lecciones aprendidas:**
> (1) **Dependabot**: Aprendi que este bot de GitHub abre PRs automaticas para mantener dependencias actualizadas (Maven y GitHub Actions). Sin embargo, puede romper el build si se aceptan cambios de major sin revision (ej. Spring Boot 3.3.5 → 4.0.6). La solucion fue configurar `ignore: update-types: semver-major` para que solo sugiera patches y minors.
> (2) **Artifacts del pipeline**: Cada job genera artifacts con propositos distintos — `app-jar` es el JAR compilado listo para deploy, `jacoco-report` es el informe de cobertura que evidencia el cumplimiento del 80%, `surefire-reports` contiene los resultados XML de los tests (para debug en caso de fallos), y `dockerbuild` es la cache de capas de Docker que acelera builds futuros reutilizando dependencias ya descargadas.
>
> ---
>
> ### Integrante 2: Eliezer Carrasco — RUT: 18.330.707-k

**Reflexión sobre CI/CD:**
A través de la implementación de este pipeline en GitHub Actions para una arquitectura basada en Spring Boot, comprendí que la Integración Continua (CI) va mucho más allá de automatizar una compilación. Su valor real radica en establecer un mecanismo de retroalimentación inmediata para el equipo de desarrollo. Al configurar disparadores automáticos ante eventos de push y pull request en la rama principal, el pipeline actúa como un guardián de la integridad del software. Automatizar fases críticas como la compilación con Maven y el empaquetado final nos permite transicionar con total confianza desde el código fuente hasta un artefacto Docker ejecutable, erradicando por completo el clásico problema de "en mi máquina sí funciona" y garantizando que cada entrega cumpla con un estándar predecible y repetible.

**Reflexión sobre calidad y seguridad:**
La incorporación de herramientas como JaCoCo y Snyk transforma radicalmente la forma en que concebimos la calidad y la seguridad dentro del ciclo de vida del desarrollo de software (DevSecOps). La métrica de cobertura provista por JaCoCo establece un umbral numérico objetivo (Quality Gate >= 80%) que nos obliga a diseñar pruebas unitarias y de integración significativas con JUnit 5, impidiendo el avance de código no validado funcionalmente. Por otra parte, la integración de Snyk añade una capa indispensable de seguridad en la cadena de suministro de software; al analizar estáticamente el `pom.xml` y las dependencias de Maven en busca de vulnerabilidades antes del despliegue, mitigamos riesgos de seguridad críticos de manera proactiva. Definir políticas severas que aborten la construcción ante hallazgos de severidad "High" o "Critical" asegura la gobernanza del proyecto y blinda el entorno productivo simulado.

**Lecciones aprendidas:**
1. **La criticidad de la gobernanza de contenedores:** Aprendí la importancia de configurar explícitamente límites de recursos físicos (CPU y Memoria RAM) mediante Docker Compose, garantizando que el microservicio no genere denegaciones de servicio locales ni costes excesivos en un ecosistema cloud real debido a fugas de memoria o hilos huérfanos.
2. **Estrategias Multi-stage para optimización:** Comprendí las ventajas arquitectónicas de separar el entorno de compilación (JDK y Maven) del entorno de ejecución (JRE Alpine ligero con usuario no-root). Esto no solo optimiza drásticamente el peso de la imagen final del contenedor, sino que reduce sustancialmente la superficie de ataque expuesta ante posibles intrusiones.
---

## 11. Licencia

Este proyecto forma parte de la Evaluacion Parcial N°2 de Ingenieria DevOps — Duoc UC.
