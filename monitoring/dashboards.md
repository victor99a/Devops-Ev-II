# Dashboards de Monitoreo — Greeting Service EP3

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

El endpoint es: `GET /actuator/prometheus`

---

## 2. Estructura del Dashboard Grafana

### 2.1 Panel: Disponibilidad del Servicio

```promql
up{app="greeting-service"}
```

**Descripción:** Estado up/down de cada pod. Si `up == 0`, el servicio está caído.

---

### 2.2 Panel: Tasa de Errores HTTP (5xx)

```promql
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
/
sum(rate(http_server_requests_seconds_count[5m]))
* 100
```

**Descripción:** Porcentaje de errores 5xx en los últimos 5 minutos.

---

### 2.3 Panel: Tasa de Errores HTTP (4xx)

```promql
sum(rate(http_server_requests_seconds_count{status=~"4.."}[5m]))
/
sum(rate(http_server_requests_seconds_count[5m]))
* 100
```

---

### 2.4 Panel: Requests por Segundo (RPS)

```promql
sum(rate(http_server_requests_seconds_count[1m]))
```

---

### 2.5 Panel: Latencia P99

```promql
histogram_quantile(0.99, sum(rate(http_server_requests_seconds_bucket[5m])) by (le))
```

---

### 2.6 Panel: Uso de CPU por Contenedor

```promql
rate(container_cpu_usage_seconds_total{namespace="greeting-app"}[5m])
```

*(Requiere métricas de kubelet o cAdvisor en el clúster)*

---

### 2.7 Panel: Uso de Memoria JVM

```promql
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100
```

---

### 2.8 Panel: Conexiones Activas a PostgreSQL (HikariCP)

```promql
hikaricp_connections_active
```

---

### 2.9 Panel: Cobertura de Pruebas

La cobertura se obtiene desde SonarCloud vía métrica externa. Configurar el datasource de SonarCloud en Grafana:

```promql
sonar_project_coverage{key="demo-ms"}
```

Alternativa: usar el Grafana plugin **SonarQube** o **REST API** via `infinity` datasource.

---

### 2.10 Panel: Tiempos de Despliegue

**Fuente:** GitHub Actions metrics exportadas a CloudWatch. Alternativa: métrica custom desde el pipeline.

Se puede enviar una métrica custom via `aws cloudwatch put-metric-data` al inicio y fin del job `deploy-k8s`:

```bash
DURATION=$(( $(date +%s) - DEPLOY_START_TIME ))
aws cloudwatch put-metric-data \
  --namespace "GreetingService/CI" \
  --metric-name "DeployDurationSeconds" \
  --value "$DURATION" \
  --unit Seconds
```

Esto se grafica en CloudWatch Dashboard o en Grafana.

---

## 3. Configuración de Prometheus ServiceMonitor

Para que Prometheus Operator descubra automáticamente los pods:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: greeting-backend
  namespace: greeting-app
spec:
  selector:
    matchLabels:
      app: backend
  endpoints:
    - port: http
      path: /actuator/prometheus
      interval: 30s
```

---

## 4. Configuración de CloudWatch Container Insights

Para EKS, habilitar Container Insights en el clúster:

```bash
aws eks update-addon \
  --cluster-name <CLUSTER_NAME> \
  --addon-name amazon-cloudwatch-observability \
  --region <REGION>
```

Esto inyecta métricas de CPU, memoria, red y disco a CloudWatch automáticamente.

---

## 5. Métricas del Pipeline CI/CD (GitHub Actions → CloudWatch)

Agregar al final del job `deploy-k8s` en `ci-cd.yml`:

```yaml
- name: Publish deploy duration metric
  run: |
    aws cloudwatch put-metric-data \
      --namespace "GreetingService/CI" \
      --metric-name "DeployDurationSeconds" \
      --value "$(( $(date +%s) - ${{ env.DEPLOY_START_EPOCH }} ))" \
      --unit Seconds \
      --region ${{ env.AWS_REGION }}
```

---

## 6. Logs Centralizados

Para CloudWatch Logs desde EKS:

1. Crear un IAM role con política `CloudWatchAgentServerPolicy`
2. Instalar Fluent Bit como DaemonSet con output a CloudWatch Logs
3. Log group naming: `/aws/eks/<cluster>/containers`

Esto centraliza los logs de todos los pods en CloudWatch Logs Insights, permitiendo queries como:

```
filter @logStream like /backend/
| filter @message like /ERROR/
| stats count() by bin(5m)
```

---

## 7. Dashboards CloudWatch Sugeridos

| Dashboard | Widgets |
|---|---|
| **Greeting-Service-Overview** | CPU/Memoria promedio de backend + frontend, RPS, Tasa de errores |
| **Greeting-Service-DB** | Conexiones HikariCP, latencia de queries, uso de storage PostgreSQL |
| **Greeting-Service-CICD** | Tiempo de deploy, cobertura de pruebas, fallos de pipeline |

---

## 8. Cobertura de Código — SonarCloud

### Integración con el Pipeline CI/CD

SonarCloud está integrado en la etapa `test-quality` del pipeline con `qualitygate.wait=true`. Los resultados de cobertura se publican automáticamente:

| Proyecto | SonarCloud Key | Fuente de cobertura |
|---|---|---|
| Backend (Java/Maven) | `victor99a_Devops-Ev-II` | JaCoCo XML (`target/site/jacoco/jacoco.xml`) |
| Frontend (React/TS) | `victor99a_Devops-Ev-II_Frontend` | LCOV (`frontend/coverage/lcov.info`) |

### Consulta de Cobertura vía API de SonarCloud

```bash
# Backend
curl -s -u "$SONAR_TOKEN:" \
  "https://sonarcloud.io/api/measures/component?component=victor99a_Devops-Ev-II&metricKeys=coverage,bugs,vulnerabilities,code_smells"

# Frontend
curl -s -u "$SONAR_TOKEN:" \
  "https://sonarcloud.io/api/measures/component?component=victor99a_Devops-Ev-II_Frontend&metricKeys=coverage,bugs,vulnerabilities,code_smells"
```

### Visualización en Grafana

Para mostrar la cobertura en un dashboard de Grafana, configurar el datasource **SonarQube**:

1. Instalar el plugin de Grafana: `grafana-cli plugins install briangann-sonarqube-datasource`
2. Configurar el datasource con URL `https://sonarcloud.io` y el token de SonarCloud
3. Agregar un panel **Gauge** con query:
   ```json
   {
     "projectKey": "victor99a_Devops-Ev-II",
     "metricKeys": "coverage"
   }
   ```

### Thresholds de Quality Gate (Fail-Fast)

| Métrica | Umbral | Acción si falla |
|---|---|---|
| Coverage | < 80% | Pipeline `exit 1` — no se despliega |
| Bugs | ≥ 1 Blocker | Pipeline `exit 1` — no se despliega |
| Vulnerabilities | ≥ 1 Critical | Pipeline `exit 1` — no se despliega |
| Code Smells | No bloqueante | Advertencia en logs del pipeline |

### Badge de Cobertura

```
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=victor99a_Devops-Ev-II&metric=coverage)](https://sonarcloud.io/dashboard?id=victor99a_Devops-Ev-II)
```

Este badge puede incluirse en el `README.md` del repositorio para visibilidad inmediata del estado de calidad.
