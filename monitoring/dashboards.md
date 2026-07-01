# Dashboards de Monitoreo — Greeting Service EP3 (EC2 + Docker Compose)

## 1. Métricas expuestas por el Backend (Micrometer + Prometheus)

| Métrica (Prometheus) | Descripción | Tipo |
|---|---|---|
| `jvm_memory_used_bytes` | Memoria JVM usada (heap + non-heap) | Gauge |
| `jvm_memory_max_bytes` | Memoria JVM máxima disponible | Gauge |
| `jvm_gc_pause_seconds_sum` | Tiempo total de pausas de GC | Counter |
| `http_server_requests_seconds_count` | Total de requests HTTP recibidos | Counter |
| `http_server_requests_seconds_sum` | Tiempo total de requests HTTP | Counter |
| `http_server_requests_seconds_bucket` | Histograma de latencia HTTP | Histogram |
| `hikaricp_connections_active` | Conexiones DB activas en el pool | Gauge |
| `hikaricp_connections_pending` | Conexiones DB pendientes | Gauge |
| `system_cpu_usage` | Uso de CPU del sistema | Gauge |
| `process_cpu_usage` | Uso de CPU del proceso JVM | Gauge |
| `application_started_time_seconds` | Tiempo que tomó iniciar la app | Gauge |
| `spring_application_ready` | Indicador de aplicación lista | Gauge |

Endpoint: `GET /actuator/prometheus`

---

## 2. Métricas de EC2 (CloudWatch Agent)

El CloudWatch Agent instalado en la EC2 vía `infra/ec2-setup.sh` recolecta:

| Métrica (CWAgent) | Descripción |
|---|---|
| `cpu_usage_user` | CPU en modo usuario (%) |
| `cpu_usage_system` | CPU en modo sistema (%) |
| `mem_used_percent` | Memoria usada (%) |
| `disk_used_percent` | Disco usado (%) |

---

## 3. Métricas del Pipeline CI/CD

Métricas custom publicadas desde GitHub Actions:

| Namespace | Métrica | Descripción |
|---|---|---|
| `GreetingService/CICD` | `DeployDurationSeconds` | Duración total del despliegue (desde job `deploy-ec2`) |
| `GreetingService/CICD` | `SmokeTestsPassed` | Cantidad de smoke tests que pasaron (0-5) |

---

## 4. Dashboard CloudWatch

Crear con: `bash monitoring/cloudwatch-dashboard.sh`

Widgets:
- CPU Utilization (CWAgent)
- Memory Utilization (CWAgent)
- Tiempo de Despliegue (custom)
- Disco usado (CWAgent)
- Smoke Tests pasados (custom)
- Errores del sistema (CloudWatch Logs)
- Errores Docker (CloudWatch Logs)

---

## 5. Dashboard Grafana

Importar `monitoring/grafana-dashboard.json` en Grafana. Requiere datasources:
- **Prometheus**: conectado a `http://<EC2_IP>:8080/actuator/prometheus` o vía Prometheus server
- **CloudWatch**: para métricas CI/CD

Paneles incluidos en el JSON:
- UP/DOWN status por servicio
- Tasa de errores HTTP 5xx
- Requests por segundo
- Latencia P99
- Requests por status code (2xx/4xx/5xx)
- Latencia HTTP percentiles (P50/P90/P99)
- CPU por contenedor
- Memoria por contenedor
- JVM Memory (Heap + Non-Heap)
- HikariCP conexiones DB
- JVM GC pause time
- Cobertura backend (SonarCloud)
- Cobertura frontend (SonarCloud)
- Tiempo de despliegue
- Smoke tests pasados

---

## 6. Cobertura de Código — SonarCloud

| Proyecto | Key | Fuente de cobertura |
|---|---|---|
| Backend (Java/Maven) | `victor99a_Devops-Ev-II` | JaCoCo XML (`target/site/jacoco/jacoco.xml`) |
| Frontend (React/TS) | `victor99a_Devops-Ev-II_Frontend` | LCOV (`frontend/coverage/lcov.info`) |

**Consulta vía API:**
```bash
curl -s -u "$SONAR_TOKEN:" \
  "https://sonarcloud.io/api/measures/component?component=victor99a_Devops-Ev-II&metricKeys=coverage,bugs,vulnerabilities"
```

**Thresholds Quality Gate:**
| Métrica | Umbral | Acción |
|---|---|---|
| Coverage | < 80% | Pipeline `exit 1` |
| Bugs | >= 1 Blocker | Pipeline `exit 1` |
| Vulnerabilities | >= 1 Critical | Pipeline `exit 1` |

---

## 7. Logs Centralizados (CloudWatch Logs)

Los logs se recolectan vía CloudWatch Agent en la EC2:

| Log Group | Fuente | Contenido |
|---|---|---|
| `/greeting-service/ec2/system` | `/var/log/messages` | Logs del sistema operativo |
| `/greeting-service/ec2/docker` | `/var/log/docker` | Logs de Docker daemon |

Los logs de los contenedores se acceden vía `docker compose logs` en la EC2 o mediante `docker logs <container>`.
