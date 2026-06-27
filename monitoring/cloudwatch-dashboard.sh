#!/bin/bash
# ──────────────────────────────────────────────────────────
# AWS CloudWatch Dashboard — Greeting Service EP3 DevOps
# Ejecuta: bash monitoring/cloudwatch-dashboard.sh
# ──────────────────────────────────────────────────────────
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
DASHBOARD_NAME="EP3-Greeting-Service-FullStack"

cat <<'DASHBOARD_JSON' > /tmp/ep3-dashboard-body.json
{
  "widgets": [
    {
      "type": "text",
      "x": 0, "y": 0, "width": 24, "height": 2,
      "properties": {
        "markdown": "## EP3 DevOps — Greeting Service Full-Stack Dashboard\n\nMonitorea disponibilidad, tasa de errores, uso de CPU/Memoria, métricas JVM, cobertura de pruebas y tiempos de despliegue."
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 2, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ContainerInsights", "node_cpu_utilization", { "stat": "Average", "period": 60 }],
          ["AWS/ContainerInsights", "pod_cpu_utilization", { "stat": "Average", "period": 60, "label": "Backend CPU" }],
          ["AWS/ContainerInsights", "pod_cpu_utilization", { "stat": "Average", "period": 60, "label": "Frontend CPU" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "REPLACE_REGION",
        "title": "CPU Utilization — Pods",
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
          ["AWS/ContainerInsights", "pod_memory_utilization", { "stat": "Average", "period": 60, "label": "Backend Mem" }],
          ["AWS/ContainerInsights", "pod_memory_utilization", { "stat": "Average", "period": 60, "label": "Frontend Mem" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "REPLACE_REGION",
        "title": "Memory Utilization — Pods",
        "yAxis": { "left": { "label": "Percent", "showUnits": false } },
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
          ["GreetingService/CICD", "SmokeTestsPassed", { "stat": "Maximum", "period": 300 }]
        ],
        "view": "singleValue",
        "region": "REPLACE_REGION",
        "title": "Smoke Tests Pasados",
        "period": 300,
        "stat": "Maximum"
      }
    },
    {
      "type": "metric",
      "x": 16, "y": 8, "width": 8, "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ContainerInsights", "pod_network_rx_bytes", { "stat": "Average", "period": 60, "label": "RX" }],
          ["AWS/ContainerInsights", "pod_network_tx_bytes", { "stat": "Average", "period": 60, "label": "TX" }]
        ],
        "view": "timeSeries",
        "region": "REPLACE_REGION",
        "title": "Network Traffic — Pods",
        "yAxis": { "left": { "label": "Bytes/s", "showUnits": false } },
        "period": 60,
        "stat": "Average"
      }
    },
    {
      "type": "log",
      "x": 0, "y": 14, "width": 12, "height": 6,
      "properties": {
        "query": "SOURCE '/aws/containerinsights/REPLACE_CLUSTER/application'\n| filter @logStream like /backend/\n| filter @message like /ERROR/\n| stats count() by bin(5m)",
        "region": "REPLACE_REGION",
        "title": "Backend Errors — CloudWatch Logs",
        "view": "timeSeries"
      }
    },
    {
      "type": "log",
      "x": 12, "y": 14, "width": 12, "height": 6,
      "properties": {
        "query": "SOURCE '/aws/containerinsights/REPLACE_CLUSTER/application'\n| filter @logStream like /frontend/\n| filter @message like /ERROR/\n| stats count() by bin(5m)",
        "region": "REPLACE_REGION",
        "title": "Frontend Errors — CloudWatch Logs",
        "view": "timeSeries"
      }
    },
    {
      "type": "text",
      "x": 0, "y": 20, "width": 24, "height": 2,
      "properties": {
        "markdown": "---\n**Métricas del pipeline CI/CD:** `GreetingService/CICD` | **Container Insights:** `AWS/ContainerInsights` | **Logs:** `/aws/containerinsights/<cluster>/application`"
      }
    }
  ]
}
DASHBOARD_JSON

sed -i '' "s/REPLACE_REGION/${AWS_REGION}/g" /tmp/ep3-dashboard-body.json
sed -i '' "s/REPLACE_CLUSTER/\${EKS_CLUSTER_NAME:-greeting-cluster}/g" /tmp/ep3-dashboard-body.json

echo "Creando CloudWatch Dashboard: ${DASHBOARD_NAME} en región ${AWS_REGION}"

aws cloudwatch put-dashboard \
  --dashboard-name "${DASHBOARD_NAME}" \
  --dashboard-body "file:///tmp/ep3-dashboard-body.json" \
  --region "${AWS_REGION}"

echo "Dashboard creado exitosamente."
echo "URL: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}"
