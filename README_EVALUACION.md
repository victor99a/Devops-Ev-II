# Informe de Evaluación Parcial N°3 — Ingeniería DevOps (DOY0101)

**Equipo:**

| Integrante | RUT |
|---|---|
| Victor Barrera Jara | 20.968.480-2 |
| Eliezer Carrasco | 18.330.707-K |

**Fecha de entrega:** Junio 2026
**Proyecto:** Greeting Service Full-Stack — Microservicios con CI/CD, Kubernetes y Observabilidad

---

## 1. Arquitectura DevOps del Proyecto

### 1.1 Visión General

El proyecto implementa una arquitectura **Full-Stack de Microservicios** compuesta por:

- **Backend:** Microservicio REST en Java 17 + Spring Boot 3.3.5 con Arquitectura Hexagonal (Puertos y Adaptadores), persistencia en PostgreSQL 15, expuesto en puerto 8080.
- **Frontend:** Aplicación SPA en React 18 + TypeScript 5 + Vite 6, servida por Nginx 1.27 en puerto 80 con reverse proxy al backend.
- **Base de Datos:** PostgreSQL 15 en contenedor dedicado.
- **Orquestación:** Kubernetes (AWS EKS) con manifiestos declarativos para todos los componentes.
- **Pipeline CI/CD:** GitHub Actions con 6 etapas secuenciales estrictas que incluyen análisis de calidad, escaneo de seguridad, construcción de imágenes Docker, despliegue automatizado en EKS y smoke tests.
- **Observabilidad:** Métricas Prometheus vía Micrometer + Actuator, logs centralizados en CloudWatch, dashboards en Grafana y CloudWatch.

### 1.2 Diagrama de Arquitectura

```
                    ┌──────────────────────────┐
                    │   GitHub Actions CI/CD    │
                    │  ┌──────────────────────┐ │
                    │  │ 1. Test & Quality    │ │
                    │  │ 2. Quality Gate      │ │
                    │  │ 3. Security (Snyk+   │ │
                    │  │    Trivy)            │ │
                    │  │ 4. Build & Push (ECR)│ │
                    │  │ 5. Deploy K8s (EKS)  │ │
                    │  │ 6. Smoke Tests       │ │
                    │  └──────────────────────┘ │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │   AWS ECR (Registro)      │
                    │  ┌─────────┐ ┌─────────┐ │
                    │  │ Backend │ │Frontend │ │
                    │  └─────────┘ └─────────┘ │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │   AWS EKS (Kubernetes)    │
                    │  ┌──────────────────────┐ │
                    │  │ Ingress (Nginx)      │ │
                    │  ├──────────────────────┤ │
                    │  │ Frontend Svc :80     │ │
                    │  │  ├─ Pod (Nginx)      │ │
                    │  │  └─ Nginx Exporter   │ │
                    │  ├──────────────────────┤ │
                    │  │ Backend Svc :8080    │ │
                    │  │  ├─ Pod 1 (JVM)      │ │
                    │  │  └─ Pod 2 (JVM)      │ │
                    │  ├──────────────────────┤ │
                    │  │ PostgreSQL :5432     │ │
                    │  └──────────────────────┘ │
                    └────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
   ┌──────▼──────┐      ┌───────▼───────┐     ┌────────▼────────┐
   │  Prometheus  │      │  CloudWatch    │     │  Grafana        │
   │  (scraping)  │      │  (logs+métrics)│     │  (dashboards)   │
   └──────────────┘      └───────────────┘     └─────────────────┘
```

### 1.3 Integración de Herramientas DevOps

La arquitectura integra las siguientes herramientas para permitir **toma de decisiones técnicas informadas basadas en datos:**

| Categoría | Herramienta | Qué mide | Decisión informada |
|---|---|---|---|
| **Calidad de Código** | SonarCloud + JaCoCo | Cobertura de pruebas, bugs, code smells, vulnerabilidades | ¿El código cumple el umbral mínimo del 80% de cobertura? ¿Hay bugs críticos que impidan el despliegue? |
| **Seguridad** | Snyk + Trivy | Vulnerabilidades en dependencias e imágenes Docker | ¿Las dependencias tienen CVEs de severidad High/Critical? ¿La imagen Docker contiene binarios vulnerables? |
| **CI/CD** | GitHub Actions + AWS ECR + EKS | Tiempo de despliegue, tasa de éxito/falo de pipelines | ¿El pipeline está ralentizando los despliegues? ¿Hay fallos recurrentes que requieran ajustes? |
| **Monitoreo** | Prometheus + Micrometer | Uso de CPU/Memoria, tasa de errores HTTP, latencia, conexiones DB | ¿El backend necesita más réplicas? ¿Hay memory leaks? ¿La latencia P99 supera el SLA? |
| **Logs** | CloudWatch Logs + Fluent Bit | Errores de aplicación, stacktraces, eventos de infraestructura | ¿Hay errores recurrentes que requieran debugging? ¿Patrones de fallo en producción? |
| **Dashboards** | Grafana + CloudWatch | Vista centralizada de todos los indicadores | ¿El servicio está saludable en este momento? ¿Hubo degradación tras el último deploy? |

### 1.4 Mecanismo Fail-Fast del Pipeline

El pipeline implementa **tres puntos de control Fail-Fast** que bloquean el despliegue ante condiciones críticas:

1. **Quality Gate (SonarCloud):** La etapa `quality-gate` consulta la API de SonarCloud. Si el Quality Gate reporta estado `ERROR` (cobertura < 80%, bugs bloqueantes, vulnerabilidades), el pipeline ejecuta `exit 1` inmediatamente. **Ningún código que no cumpla los estándares llega a producción.**

2. **Security Scan (Snyk):** El comando `snyk test --severity-threshold=high` retorna código de salida distinto de cero si encuentra al menos una vulnerabilidad High o Critical. El pipeline se detiene y el despliegue se bloquea.

3. **Trivy Image Scan:** Antes del push a ECR, Trivy escanea las imágenes Docker en busca de vulnerabilidades CRITICAL o HIGH (`trivy-action` con `exit-code: 1`). Si encuentra alguna, la imagen **no se publica en ECR** y el pipeline falla.

Adicionalmente, cada paso crítico usa `set -euo pipefail` para que cualquier comando que falle (curl, kubectl, etc.) detenga el flujo inmediatamente.

### 1.5 Estrategia de Monitoreo y Observabilidad

- **Backend:** Expone métricas JVM, HTTP y de base de datos en `/actuator/prometheus` vía Micrometer + Prometheus registry.
- **Frontend:** Métricas de Nginx expuestas vía sidecar `nginx-prometheus-exporter` en puerto 9113.
- **Descubrimiento automático:** Los Services K8s llevan anotaciones `prometheus.io/scrape: "true"`. Adicionalmente, se proveen `ServiceMonitor` CRDs para Prometheus Operator.
- **Dashboards:** Un dashboard de Grafana (JSON incluido en `monitoring/`) y un script de CloudWatch Dashboard consolidan CPU, memoria, tasa de errores, latencia, cobertura y tiempos de despliegue en una vista única.

---

## 2. Estructura del Proyecto

```
Devops-Ev-II/
├── pom.xml                              # Backend: Spring Boot 3.3.5 + Micrometer + JaCoCo
├── Dockerfile                           # Backend multi-stage (Maven → JRE Alpine)
├── docker-compose.yml                   # Orquestación local (app + PostgreSQL)
├── src/                                 # Backend — Arquitectura Hexagonal
│   ├── main/java/com/example/demo/
│   │   ├── domain/                      # Entidades, Puertos (inbound/outbound)
│   │   ├── application/service/         # Casos de uso
│   │   └── infrastructure/              # Adaptadores REST, JPA
│   ├── main/resources/application.yml   # Config: PostgreSQL, Actuator, Prometheus
│   └── test/                            # 19 tests unitarios (JUnit 5, Mockito)
│
├── frontend/                            # Frontend — React 18 + TypeScript + Vite
│   ├── package.json / tsconfig.json
│   ├── vite.config.ts                   # Proxy /api → backend en dev
│   ├── Dockerfile                       # Multi-stage (node build → nginx serve)
│   ├── nginx.conf                       # Reverse proxy /api, health endpoint
│   └── src/
│       ├── App.tsx / App.css            # UI Dark Premium
│       └── api/greeting.ts              # Cliente REST (axios)
│
├── k8s/                                 # Manifiestos Kubernetes
│   ├── namespace.yaml                   # Namespace: greeting-app
│   ├── configmap.yaml / secret.yaml     # Configuración + credenciales DB
│   ├── postgres-deployment.yaml         # PostgreSQL Deployment + PVC
│   ├── postgres-service.yaml            # Service ClusterIP :5432
│   ├── backend-deployment.yaml          # Backend Deployment (2 réplicas)
│   ├── backend-service.yaml             # Service ClusterIP :8080 + Prometheus annotations
│   ├── frontend-deployment.yaml         # Frontend Deployment (2 réplicas + nginx-exporter)
│   ├── frontend-service.yaml            # Service ClusterIP :80 + :9113 (metrics)
│   ├── ingress.yaml                     # Ingress Nginx
│   └── servicemonitor.yaml              # ServiceMonitor CRDs (Prometheus Operator)
│
├── monitoring/                          # Observabilidad
│   ├── dashboards.md                    # Documentación de métricas y queries PromQL
│   ├── grafana-dashboard.json           # Dashboard Grafana completo (JSON)
│   └── cloudwatch-dashboard.sh          # Script de creación de CloudWatch Dashboard
│
└── .github/workflows/
    └── ci-cd.yml                        # Pipeline CI/CD: 6 etapas secuenciales
```

---

## 3. Endpoints y Métricas

### 3.1 Backend API

| Método | Path | Descripción |
|---|---|---|
| `GET` | `/api/v1/greetings` | Listar todos los saludos |
| `POST` | `/api/v1/greetings?name=...` | Crear nuevo saludo |
| `GET` | `/api/v1/greetings/{id}` | Buscar saludo por ID |
| `GET` | `/actuator/health` | Health check (K8s probes) |
| `GET` | `/actuator/metrics` | Métricas de Spring Boot |
| `GET` | `/actuator/prometheus` | Métricas en formato Prometheus |

### 3.2 Frontend Endpoints

| Path | Descripción |
|---|---|
| `/` | SPA (React) |
| `/health` | Health check Nginx (K8s probes + nginx-exporter scrape) |

### 3.3 Métricas Clave Expuestas

| Métrica Prometheus | Tipo | Significado |
|---|---|---|
| `up` | Gauge | Disponibilidad del servicio (1 = UP, 0 = DOWN) |
| `http_server_requests_seconds_count` | Counter | Total de requests HTTP |
| `http_server_requests_seconds_sum` | Counter | Suma de latencias HTTP |
| `http_server_requests_seconds_bucket` | Histogram | Distribución de latencias |
| `jvm_memory_used_bytes` | Gauge | Memoria JVM usada |
| `jvm_memory_max_bytes` | Gauge | Memoria JVM máxima |
| `jvm_gc_pause_seconds_sum` | Counter | Tiempo total de pausas GC |
| `hikaricp_connections_active` | Gauge | Conexiones DB activas |
| `process_cpu_usage` | Gauge | CPU del proceso JVM |
| `application_started_time_seconds` | Gauge | Tiempo de startup |

---

## 4. Pipeline CI/CD — Detalle de Etapas

| # | Etapa | Herramientas | Criterio Fail-Fast |
|---|---|---|---|
| 1 | **Test & Quality** | Maven, JUnit 5, JaCoCo, SonarCloud, Vitest | `mvn verify` falla si cobertura < 80% o tests fallan. SonarCloud `qualitygate.wait=true` |
| 2 | **Quality Gate** | SonarCloud Quality Gate Action | `exit 1` si el Quality Gate reporta ERROR |
| 3 | **Security Scan** | Snyk (dependencias) | `snyk test --severity-threshold=high` retorna exit code ≠ 0 |
| 4 | **Build & Push** | Docker Buildx, Trivy, ECR | Trivy `exit-code: 1` si detecta CRITICAL/HIGH. Imágenes no se publican |
| 5 | **Deploy K8s** | AWS CLI, kubectl, EKS | `kubectl rollout status` con timeout; falla si pods no están Ready |
| 6 | **Smoke Tests** | curl via pods temporales | `exit 1` si health, API o métricas no responden correctamente |

---

## 5. Análisis de Resultados y Decisiones Basadas en Datos

*(Esta sección describe cómo las métricas y herramientas de observabilidad permiten tomar decisiones técnicas. Completar con datos reales de ejecución.)*

### 5.1 Disponibilidad

| Indicador | Herramienta | Valor | Umbral |
|---|---|---|---|
| Uptime Backend | Prometheus `up` | `[COMPLETAR]` | ≥ 99.5% |
| Uptime Frontend | Prometheus `up` | `[COMPLETAR]` | ≥ 99.5% |

### 5.2 Rendimiento

| Indicador | Herramienta | Valor | Umbral |
|---|---|---|---|
| Latencia P99 Backend | Prometheus histogram | `[COMPLETAR]` | < 500ms |
| Requests por segundo | Prometheus `rate()` | `[COMPLETAR]` | — |
| Tasa de error 5xx | Prometheus | `[COMPLETAR]` | < 1% |

### 5.3 Recursos

| Indicador | Herramienta | Valor | Umbral |
|---|---|---|---|
| CPU Backend | CloudWatch / cAdvisor | `[COMPLETAR]` | < 80% del limit |
| Memoria Backend | CloudWatch / cAdvisor | `[COMPLETAR]` | < 80% del limit |
| Conexiones DB activas | HikariCP metrics | `[COMPLETAR]` | < 10 |

### 5.4 Calidad de Código

| Indicador | Herramienta | Valor | Umbral |
|---|---|---|---|
| Cobertura Backend | SonarCloud / JaCoCo | `[COMPLETAR]` | ≥ 80% |
| Cobertura Frontend | SonarCloud / Vitest | `[COMPLETAR]` | ≥ 70% |
| Vulnerabilidades (Snyk) | Snyk | `[COMPLETAR]` | 0 High/Critical |
| Vulnerabilidades (Imagen) | Trivy | `[COMPLETAR]` | 0 High/Critical |

### 5.5 Despliegue

| Indicador | Herramienta | Valor | Umbral |
|---|---|---|---|
| Tiempo de despliegue | CloudWatch `DeployDurationSeconds` | `[COMPLETAR]` | < 300s |
| Smoke tests pasados | CloudWatch | `[COMPLETAR]` | 4/4 |

---

## 6. Configuración de Secrets y Variables

### 6.1 GitHub Secrets requeridos

| Secret | Propósito |
|---|---|
| `SONAR_TOKEN` | Autenticación con SonarCloud |
| `SNYK_TOKEN` | Autenticación con Snyk |
| `AWS_ACCESS_KEY_ID` | Credenciales AWS para ECR + EKS |
| `AWS_SECRET_ACCESS_KEY` | Credenciales AWS para ECR + EKS |

### 6.2 GitHub Variables requeridas

| Variable | Valor esperado | Propósito |
|---|---|---|
| `SONAR_ORG` | Nombre de organización en SonarCloud | Análisis de calidad |
| `AWS_DEPLOY_ROLE` | ARN del rol IAM para despliegue | Autenticación OIDC con AWS |
| `EKS_CLUSTER_NAME` | Nombre del cluster EKS | Conexión kubectl |

### 6.3 Repositorios ECR requeridos

```bash
aws ecr create-repository --repository-name demo-ms-backend --region us-east-1
aws ecr create-repository --repository-name demo-ms-frontend --region us-east-1
```

---

## 7. Instrucciones de Despliegue

### 7.1 Local (Docker Compose)

```bash
mvn clean verify                     # Tests + coverage
docker compose up -d --build         # Levanta backend + PostgreSQL
cd frontend && npm run dev           # Frontend en http://localhost:5173
```

### 7.2 Producción (EKS)

```bash
# El despliegue es automático vía GitHub Actions al hacer push a main.
# Manualmente:
aws eks update-kubeconfig --region us-east-1 --name <CLUSTER_NAME>
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/
kubectl rollout status deployment/backend -n greeting-app
kubectl rollout status deployment/frontend -n greeting-app
```

---

## 8. Configuración de Dashboards

### 8.1 Grafana

1. Importar `monitoring/grafana-dashboard.json` en Grafana.
2. Configurar datasources: Prometheus (para métricas de aplicación) y CloudWatch (para métricas de CI/CD).
3. El dashboard mostrará automáticamente todas las métricas de los paneles descritos en la sección 1.5.

### 8.2 CloudWatch

```bash
bash monitoring/cloudwatch-dashboard.sh
```

---

## 9. Declaración de Uso Ético de Inteligencia Artificial

De acuerdo con las políticas de integridad académica de Duoc UC y la guía de uso de inteligencia artificial disponible en [https://bibliotecas.duoc.cl/ia](https://bibliotecas.duoc.cl/ia), el equipo declara que las siguientes herramientas de inteligencia artificial fueron utilizadas durante el desarrollo de este proyecto:

| Herramienta | Versión / Modelo | Propósito específico | Entregable impactado |
|---|---|---|---|
| **OpenCode (deepseek-v4-pro)** | Junio 2026 | Diseño e implementación de la arquitectura hexagonal (Puertos y Adaptadores) para el backend: estructura de paquetes, interfaces de puertos, adaptadores REST y JPA. | `src/main/java/com/example/demo/domain/`, `application/`, `infrastructure/` |
| **OpenCode (deepseek-v4-pro)** | Junio 2026 | Generación de pruebas unitarias con JUnit 5, Mockito y MockMvc para capa de aplicación, controlador REST y adaptador de persistencia (19 tests). | `src/test/` |
| **OpenCode (deepseek-v4-pro)** | Junio 2026 | Creación del frontend React + TypeScript + Vite con diseño Dark Premium, incluyendo componente App, estilos CSS, configuración de Vite y cliente HTTP con axios. | `frontend/` |
| **OpenCode (deepseek-v4-pro)** | Junio 2026 | Generación de manifiestos Kubernetes (Deployments, Services, Ingress, ServiceMonitor, ConfigMap, Secret) para despliegue en AWS EKS con anotaciones de monitoreo Prometheus. | `k8s/` |
| **OpenCode (deepseek-v4-pro)** | Junio 2026 | Diseño del pipeline CI/CD completo en GitHub Actions con 6 etapas secuenciales, mecanismo Fail-Fast (SonarCloud Quality Gate + Snyk + Trivy), build multi-stage Docker, push a ECR y despliegue automatizado en EKS. | `.github/workflows/ci-cd.yml` |
| **OpenCode (deepseek-v4-pro)** | Junio 2026 | Configuración de monitoreo: integración Micrometer + Prometheus en backend, sidecar nginx-exporter en frontend, dashboard Grafana JSON, script CloudWatch Dashboard, y documentación de métricas. | `monitoring/`, `pom.xml`, `application.yml` |
| **OpenCode (deepseek-v4-pro)** | Junio 2026 | Estructura y redacción del presente informe de evaluación (`README_EVALUACION.md`), incluyendo secciones de arquitectura, análisis de resultados y declaración de uso de IA. | `README_EVALUACION.md` |

### Método de Validación

Todo el código generado con asistencia de IA fue revisado y validado mediante:

- Ejecución de `mvn verify` verificando que los 19 tests unitarios pasan y el Quality Gate de JaCoCo (80% de cobertura de línea) se cumple.
- Ejecución de `npm run build` verificando que el frontend compila sin errores de TypeScript y genera el bundle de producción correctamente.
- Verificación de que los manifiestos Kubernetes son sintácticamente válidos y contienen todas las anotaciones de monitoreo requeridas.
- Revisión manual de la arquitectura hexagonal para confirmar que las dependencias apuntan hacia adentro y el dominio no tiene acoplamiento a frameworks externos.

### Compromiso Ético

El equipo certifica que comprende el funcionamiento de cada componente entregado, ha revisado el código generado, y asume responsabilidad plena sobre el producto final. La IA fue utilizada como herramienta de aceleración y asistencia, no como reemplazo del criterio técnico ni de la comprensión de los conceptos de DevOps evaluados.

Declaración firmada por:

- **Victor Barrera Jara** — 20.968.480-2
- **Eliezer Carrasco** — 18.330.707-K

---

## 10. ⚠️ REFLEXIONES INDIVIDUALES OBLIGATORIAS

> **⚠️ ADVERTENCIA IMPORTANTE: ESTA SECCIÓN DEBE SER REDACTADA DE FORMA MANUAL Y SIN ASISTENCIA DE INTELIGENCIA ARTIFICIAL POR CADA INTEGRANTE DEL EQUIPO.**
>
> La rúbrica de evaluación exige que las reflexiones individuales reflejen el aprendizaje y pensamiento crítico personal de cada estudiante. El uso de IA generativa para redactar esta sección constituye una violación a las políticas de integridad académica de Duoc UC.
>
> Cada integrante debe completar su reflexión en primera persona, describiendo su experiencia personal con las herramientas y conceptos aprendidos durante el desarrollo del proyecto.

---

### Integrante 1: Victor Barrera Jara — 20.968.480-2

#### Reflexión sobre CI/CD y Automatización (IE5 — 20%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Describa aquí su experiencia personal implementando el pipeline CI/CD. ¿Qué aprendió sobre la automatización de builds, tests, análisis de calidad y despliegues? ¿Cómo cambió su percepción sobre la integración continua y el despliegue continuo? ¿Qué desafíos enfrentó al configurar el Quality Gate y el mecanismo Fail-Fast?

*(Escriba su reflexión aquí...)*

---

#### Reflexión sobre Calidad y Seguridad (IE6 — 20%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Reflexione sobre el uso de SonarCloud, Snyk y Trivy como herramientas de calidad y seguridad. ¿Cómo estas herramientas ayudan a prevenir que código vulnerable o de baja calidad llegue a producción? ¿Qué aprendió sobre DevSecOps y la importancia de integrar seguridad desde las primeras etapas del pipeline?

*(Escriba su reflexión aquí...)*

---

#### Reflexión sobre Monitoreo y Observabilidad (IE1 — 20% + IE3 — 10%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Describa cómo las métricas de Prometheus, los dashboards de Grafana y los logs de CloudWatch permiten tomar decisiones informadas sobre la salud del sistema. ¿Qué indicadores considera más críticos para un microservicio en producción? ¿Cómo se relaciona la observabilidad con la confiabilidad del servicio (SRE)?

*(Escriba su reflexión aquí...)*

---

#### Reflexión sobre Orquestación con Kubernetes (IE2 — 20%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Explique su experiencia con Kubernetes como plataforma de orquestación. ¿Qué ventajas ofrece sobre un despliegue tradicional con Docker Compose? ¿Qué aprendió sobre Deployments, Services, Ingress, Probes y Resource Management? ¿Cómo contribuyen las anotaciones de Prometheus al monitoreo automatizado?

*(Escriba su reflexión aquí...)*

---

### Integrante 2: Eliezer Carrasco — 18.330.707-K

#### Reflexión sobre CI/CD y Automatización (IE5 — 20%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Describa aquí su experiencia personal con el pipeline CI/CD implementado. ¿Qué conceptos de automatización considera más valiosos? ¿Cómo el pipeline facilita la colaboración en equipo y reduce errores humanos en el proceso de despliegue?

*(Escriba su reflexión aquí...)*

---

#### Reflexión sobre Calidad y Seguridad (IE6 — 20%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Analice el impacto de integrar herramientas de calidad (SonarCloud, JaCoCo) y seguridad (Snyk, Trivy) en el flujo de desarrollo. ¿Qué relación existe entre la cobertura de pruebas y la confianza en el código? ¿Cómo contribuye el escaneo de imágenes Docker a la seguridad de la cadena de suministro?

*(Escriba su reflexión aquí...)*

---

#### Reflexión sobre Monitoreo y Observabilidad (IE1 — 20% + IE3 — 10%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Reflexione sobre la importancia de contar con dashboards centralizados que muestren métricas de todos los microservicios. ¿Cómo ayudan estas visualizaciones a detectar problemas antes de que afecten a los usuarios? ¿Qué relación ve entre observabilidad y madurez DevOps?

*(Escriba su reflexión aquí...)*

---

#### Reflexión sobre Orquestación con Kubernetes (IE2 — 20%)

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Describa su comprensión de cómo Kubernetes gestiona el ciclo de vida de los contenedores. ¿Qué papel juegan los Readiness y Liveness Probes en la disponibilidad del servicio? ¿Cómo los Resource Limits y Requests contribuyen a la estabilidad del clúster?

*(Escriba su reflexión aquí...)*

---

## 11. Lecciones Aprendidas (Grupal)

*(Esta sección puede ser completada en conjunto después de las reflexiones individuales.)*

### 11.1 ¿Qué haríamos diferente?

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Describan como equipo qué decisiones de diseño, arquitectura o implementación cambiarían si tuvieran que empezar el proyecto desde cero.

*(Escriban aquí...)*

---

### 11.2 Herramientas más valiosas

> **[COMPLETAR DE FORMA MANUAL — SIN USO DE IA]**
>
> Indiquen cuáles herramientas del stack DevOps utilizado consideran más valiosas para su futuro profesional y por qué.

*(Escriban aquí...)*

---

## 12. Licencia

Este proyecto forma parte de la Evaluación Parcial N°3 de Ingeniería DevOps (DOY0101) — Duoc UC.

---

*Anexos:*
- `monitoring/grafana-dashboard.json` — Dashboard de Grafana
- `monitoring/cloudwatch-dashboard.sh` — Script de CloudWatch Dashboard
- `monitoring/dashboards.md` — Documentación de métricas y queries PromQL
- `.github/workflows/ci-cd.yml` — Pipeline CI/CD completo
