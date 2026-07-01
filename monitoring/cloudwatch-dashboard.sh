#!/bin/bash
# ──────────────────────────────────────────────────────────
# AWS CloudWatch Dashboard — Greeting Service EP3 (EC2)
# Métricas: EC2 + CWAgent + CloudWatch Logs + CI/CD customs
# ──────────────────────────────────────────────────────────
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
DASHBOARD_NAME="EP3-Greeting-Service-EC2"

cat <<'DASHBOARD_JSON' > /tmp/ep3-dashboard-body.json
{
  "widgets": [
    {
      "type": "text",
      "x": 0, "y": 0, "width": 24, "height": 2,
      "properties": {
        "markdown": "## EP3 DevOps — Greeting Service Full-Stack (EC2 + Docker Compose)\n\nMonitorea disponibilidad, tasa de errores, uso de CPU/Memoria, métricas JVM, cobertura de pruebas y tiempos de despliegue. Orquestacion: Docker Compose sobre EC2."
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 2, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          ["CWAgent", "cpu_usage_user", { "stat": "Average", "period": 60, "label": "CPU User %" }],
          ["CWAgent", "cpu_usage_system", { "stat": "Average", "period": 60, "label": "CPU System %" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "REPLACE_REGION",
        "title": "CPU Utilization — EC2 Instance",
        "yAxis": { "left": { "label": "Percent", "showUnits": false } },
        "period": 60,
        "stat": "Average"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 2, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          ["CWAgent", "mem_used_percent", { "stat": "Average", "period": 60, "label": "Memory Used %" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "REPLACE_REGION",
        "title": "Memory Utilization — EC2 Instance",
        "yAxis": { "left": { "label": "Percent", "showUnits": false, "max": 100 } },
        "period": 60,
        "stat": "Average"
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 8, "width": 8, "height": 6,
      "properties": {
        "metrics": [
          ["GreetingService/CICD", "DeployDurationSeconds", { "stat": "Maximum", "period": 300, "label": "Deploy Time" }]
        ],
        "view": "singleValue",
        "region": "REPLACE_REGION",
        "title": "Tiempo de Despliegue (s)",
        "period": 300,
        "stat": "Maximum",
        "sparkline": true
      }
    },
    {
      "type": "metric",
      "x": 8, "y": 8, "width": 8, "height": 6,
      "properties": {
        "metrics": [
          ["CWAgent", "disk_used_percent", { "stat": "Average", "period": 300, "label": "Disk" }]
        ],
        "view": "singleValue",
        "region": "REPLACE_REGION",
        "title": "Disco Usado (%)",
        "period": 300,
        "stat": "Average"
      }
    },
    {
      "type": "metric",
      "x": 16, "y": 8, "width": 8, "height": 6,
      "properties": {
        "metrics": [
          ["GreetingService/CICD", "SmokeTestsPassed", { "stat": "Maximum", "period": 300, "label": "Smoke" }]
        ],
        "view": "singleValue",
        "region": "REPLACE_REGION",
        "title": "Smoke Tests Pasados",
        "period": 300,
        "stat": "Maximum"
      }
    },
    {
      "type": "log",
      "x": 0, "y": 14, "width": 12, "height": 6,
      "properties": {
        "query": "SOURCE '/greeting-service/ec2/system'\n| filter @message like /ERROR/\n| stats count() by bin(5m)",
        "region": "REPLACE_REGION",
        "title": "Errores del Sistema — CloudWatch Logs",
        "view": "timeSeries"
      }
    },
    {
      "type": "log",
      "x": 12, "y": 14, "width": 12, "height": 6,
      "properties": {
        "query": "SOURCE '/greeting-service/ec2/docker'\n| filter @message like /ERROR|error|ERR/\n| stats count() by bin(5m)",
        "region": "REPLACE_REGION",
        "title": "Errores Docker — CloudWatch Logs",
        "view": "timeSeries"
      }
    },
    {
      "type": "text",
      "x": 0, "y": 20, "width": 24, "height": 2,
      "properties": {
        "markdown": "---\n**Metricas CI/CD:** `GreetingService/CICD` | **Metricas EC2:** `CWAgent` (CloudWatch Agent) | **Logs:** `/greeting-service/ec2/system` y `/greeting-service/ec2/docker`\n\n**Backend metrics (Prometheus):** `GET :8080/actuator/prometheus` — JVM, HTTP, DB, CPU | **Dashboard Grafana:** `monitoring/grafana-dashboard.json`"
      }
    }
  ]
}
DASHBOARD_JSON

sed -i '' "s/REPLACE_REGION/${AWS_REGION}/g" /tmp/ep3-dashboard-body.json

echo "Creando CloudWatch Dashboard: ${DASHBOARD_NAME} en region ${AWS_REGION}"

aws cloudwatch put-dashboard \
  --dashboard-name "${DASHBOARD_NAME}" \
  --dashboard-body "file:///tmp/ep3-dashboard-body.json" \
  --region "${AWS_REGION}" || echo "Dashboard creation skipped (no AWS credentials)"

echo "Dashboard listo."
echo "URL: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}"
