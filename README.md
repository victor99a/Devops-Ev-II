# demo-ms — Microservicio Base para Evaluacion de CI/CD

Microservicio REST desarrollado en **Java 21** con **Spring Boot 3.3.5**, contenerizado con Docker multi-stage y orquestado via GitHub Actions con pipeline completo de CI/CD que incluye calidad de codigo, escaneo de seguridad y despliegue automatizado validado.

---

## 1. Arquitectura del Proyecto

```
demo-ms/
├── .github/
│   ├── workflows/ci.yml          # Pipeline CI/CD (GitHub Actions)
│   └── dependabot.yml            # Actualizacion automatica de dependencias
├── .snyk                         # Politica de exclusion de Snyk
├── Dockerfile                    # Multi-stage: build (Maven/JDK 21) + run (JRE Alpine)
├── docker-compose.yml            # Orquestacion local con limites de recursos
├── pom.xml                       # Maven + Spring Boot 3.3.5 + JaCoCo + Surefire
├── src/main/java/com/example/demo/
│   ├── DemoApplication.java      # Entry point
│   ├── controller/GreetingController.java   # GET /api/v1/greeting
│   ├── service/GreetingService.java         # Logica de negocio
│   └── model/GreetingResponse.java          # Record DTO
├── src/main/resources/application.yml
└── src/test/java/com/example/demo/
    ├── controller/GreetingControllerTest.java  # @WebMvcTest + MockMvc (3 tests)
    └── service/GreetingServiceTest.java        # Unit tests puros (5 tests)
```

---

## 2. Arquitectura del Pipeline CI/CD

```
                  PUSH / PR a main
                        │
                 ┌──────▼──────┐
                 │ Build, Test │  mvn clean verify
                 │  & Coverage │  JUnit 5 (8 tests)
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
                 │             │  curl /api/v1/greeting
                 │             │  docker inspect (health status)
                 │             │  docker compose down
                 └─────────────┘
```

### Etapas y trazabilidad

| Etapa | Herramienta | Artefacto generado | Validacion |
|---|---|---|---|
| **Build & Test** | Maven, JUnit 5, JaCoCo | `surefire-reports`, `jacoco-report`, JAR | Quality Gate 80% line coverage |
| **Security** | Snyk | Reporte de vulnerabilidades en consola | Falla si encuentra High o Critical |
| **Deploy** | Docker Compose, curl | `docker build` cache | HTTP 200 en `/actuator/health` y `/api/v1/greeting` + `docker inspect` healthy |
| **Dependabot** | GitHub Dependabot | PRs automaticas semanales | Maven + GitHub Actions |

### Reglas de calidad (Quality Gates)

- **JaCoCo**: `mvn verify` falla si la cobertura de lineas es menor a **80%**
- **Snyk**: el pipeline falla si se detecta al menos una vulnerabilidad de severidad **High** o **Critical**
- **JUnit**: 8 pruebas que validan controlador (MockMvc) y servicio (tests puros)
- **Endpoint validation**: curl con reintentos cada 3s (hasta 20 intentos) + healthcheck de Docker

---

## 3. Contenerizacion

### Dockerfile (multi-stage)

| Etapa | Imagen | Proposito |
|---|---|---|
| `build` | `maven:3.9-eclipse-temurin-21-alpine` | Compilar JAR |
| `run` | `eclipse-temurin:21-jre-alpine` | Ejecutar con usuario no-root (`appuser`) |

### docker-compose.yml

- `restart: unless-stopped`
- Limites: CPU 1.0 / Mem 512M (reservas: 0.5 CPU / 256M)
- Healthcheck via `wget` contra `/actuator/health`

---

## 4. Monitoreo de Dependencias

El archivo `.github/dependabot.yml` configura actualizaciones semanales (lunes 09:00 America/Santiago):

- **maven**: `pom.xml` — max 10 PRs abiertas
- **github-actions**: todos los workflows — max 5 PRs abiertas

---

## 5. Configuracion de Seguridad (IE3)

### Snyk

El job `security` ejecuta `snyk test --severity-threshold=high` sobre el proyecto Maven. Requiere el secreto `SNYK_TOKEN` configurado en el repositorio:

```
Settings > Secrets and variables > Actions > New repository secret
Name:  SNYK_TOKEN
Value: <token obtenido de https://app.snyk.io/account>
```

La politica `.snyk` excluye directorios de build (`target/`) y reporta solo severidades High y Critical.

---

## 6. Endpoints

| Metodo | Path | Descripcion |
|---|---|---|
| `GET` | `/api/v1/greeting` | Saludo con nombre por defecto "World" |
| `GET` | `/api/v1/greeting?name=DevOps` | Saludo personalizado |
| `GET` | `/actuator/health` | Health check de Spring Boot Actuator |

Ejemplo de respuesta:

```json
{
  "message": "Hello, DevOps!",
  "name": "DevOps",
  "timestamp": "2026-05-28T20:23:32.456Z"
}
```

---

## 7. Ejecucion local

```bash
# Build + tests + coverage
mvn clean verify

# Levantar con Docker Compose
docker compose up -d

# Probar
curl http://localhost:8080/api/v1/greeting?name=Duoc
curl http://localhost:8080/actuator/health

# Detener
docker compose down
```

---

## 8. ⚠️ PLACEHOLDER — Declaracion de Uso de IA

> **[COMPLETAR POR EL EQUIPO]**
>
> Durante el desarrollo de este proyecto, se utilizaron las siguientes herramientas de inteligencia artificial:
>
> | Herramienta | Proposito | Entregable impactado |
> |---|---|---|
> | _(ej: GitHub Copilot)_ | _(ej: generacion de boilerplate)_ | _(ej: GreetingService.java)_ |
> | _(ej: ChatGPT / Claude)_ | _(ej: revision de pipeline YAML)_ | _(ej: ci.yml)_ |
>
> Declaracion firmada por:
> - [Nombre integrante 1] — [RUT]
> - [Nombre integrante 2] — [RUT]

---

## 9. ⚠️ PLACEHOLDER — Reflexiones Individuales Obligatorias

> **[COMPLETAR POR CADA INTEGRANTE]**
>
> ### Integrante 1: [Nombre completo]
>
> **Reflexion sobre CI/CD:**
> _(Describir que se aprendio sobre integracion continua, despliegue continuo, y como este pipeline automatiza la deteccion temprana de errores y vulnerabilidades.)_
>
> **Reflexion sobre calidad y seguridad:**
> _(Comentar como herramientas como JaCoCo y Snyk contribuyen a la calidad del software y a la seguridad de la cadena de suministro.)_
>
> **Lecciones aprendidas:**
> _(Mencionar al menos 2 lecciones concretas del proceso de implementacion del pipeline.)_
>
> ---
>
> ### Integrante 2: [Nombre completo]
>
> **Reflexion sobre CI/CD:**
> _(Idem.)_
>
> **Reflexion sobre calidad y seguridad:**
> _(Idem.)_
>
> **Lecciones aprendidas:**
> _(Idem.)_

---

## 10. Licencia

Este proyecto forma parte de la Evaluacion Parcial N°2 de Ingenieria DevOps — Duoc UC.
