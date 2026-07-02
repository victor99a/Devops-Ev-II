#!/bin/bash
# ──────────────────────────────────────────────────────────
# AWS CloudWatch Dashboard — Greeting Service EP3 (v2)
# Métricas: AWS/EC2 nativas + CI/CD customs + resumen
# ──────────────────────────────────────────────────────────
set -euo pipefail

AWS_REGION="us-east-1"
INSTANCE_ID="i-01e2cf576e5f183ad"
DASHBOARD_NAME="EP3-Greeting-Service-EC2"

# Borrar viejo y recrear
aws cloudwatch delete-dashboards --dashboard-names "$DASHBOARD_NAME" --region "$AWS_REGION" 2>/dev/null || true

cat <<DASHBOARD_JSON > /tmp/ep3-dashboard-body.json
{
  "widgets": [
    {
      "type": "text",
      "x": 0, "y": 0, "width": 24, "height": 2,
      "properties": {
        "markdown": "## EP3 DevOps — Greeting Service Full-Stack\\n\\n**EC2:** $INSTANCE_ID | **Frontend:** http://100.54.219.189 | **Prometheus:** :8080/actuator/prometheus | **SonarCloud:** victor99a_Devops-Ev-II"
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 2, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", "InstanceId", "$INSTANCE_ID", { "stat": "Average", "period": 300, "label": "CPU %" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$AWS_REGION",
        "title": "CPU Utilization — EC2",
        "yAxis": { "left": { "label": "Percent", "showUnits": false } },
        "stat": "Average",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 2, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2", "NetworkIn", "InstanceId", "$INSTANCE_ID", { "stat": "Average", "period": 300, "label": "RX" }],
          ["AWS/EC2", "NetworkOut", "InstanceId", "$INSTANCE_ID", { "stat": "Average", "period": 300, "label": "TX" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$AWS_REGION",
        "title": "Network Traffic — EC2 (bytes/s)",
        "yAxis": { "left": { "label": "Bytes", "showUnits": false } },
        "stat": "Average",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 8, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", "InstanceId", "$INSTANCE_ID", { "stat": "Maximum", "period": 300 }],
          ["AWS/EC2", "CPUUtilization", "InstanceId", "$INSTANCE_ID", { "stat": "Average", "period": 300 }]
        ],
        "view": "singleValue",
        "region": "$AWS_REGION",
        "title": "CPU — Max & Avg (%)",
        "stat": "Maximum",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 8, "width": 6, "height": 6,
      "properties": {
        "metrics": [
          ["GreetingService/CICD", "DeployDurationSeconds", "Pipeline", "EP3", "Service", "FullStack", { "stat": "Maximum", "period": 300, "label": "s" }]
        ],
        "view": "singleValue",
        "region": "$AWS_REGION",
        "title": "Deploy Time (s)",
        "stat": "Maximum",
        "period": 300,
        "sparkline": true
      }
    },
    {
      "type": "metric",
      "x": 18, "y": 8, "width": 6, "height": 6,
      "properties": {
        "metrics": [
          ["GreetingService/CICD", "SmokeTestsPassed", "Pipeline", "EP3", "Service", "FullStack", { "stat": "Maximum", "period": 300 }]
        ],
        "view": "singleValue",
        "region": "$AWS_REGION",
        "title": "Smoke Tests",
        "stat": "Maximum",
        "period": 300
      }
    },
    {
      "type": "text",
      "x": 0, "y": 14, "width": 24, "height": 6,
      "properties": {
        "markdown": "### Indicadores en Vivo\\n\\n| Fuente | Métrica | Valor |\\n|---|---|---|\\n| Prometheus | POST 201 (success) | 4,449 |\\n| Prometheus | GET 400 (bad req) | 30 |\\n| Prometheus | GET 500 (server err) | 2 |\\n| Prometheus | JVM Heap Eden | 16 MB |\\n| Prometheus | HikariCP connections | 10 |\\n| SonarCloud | Coverage Backend | [Dashboard](https://sonarcloud.io/dashboard?id=victor99a_Devops-Ev-II) |\\n| GitHub Actions | Pipeline 4/4 | [History](https://github.com/victor99a/Devops-Ev-II/actions) |"
      }
    }
  ]
}
DASHBOARD_JSON

aws cloudwatch put-dashboard \
  --dashboard-name "${DASHBOARD_NAME}" \
  --dashboard-body "file:///tmp/ep3-dashboard-body.json" \
  --region "${AWS_REGION}" 2>&1

echo ""
echo "Dashboard listo:"
echo "https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}"
