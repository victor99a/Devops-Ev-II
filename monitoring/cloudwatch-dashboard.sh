#!/bin/bash
# ──────────────────────────────────────────────────────────
# AWS CloudWatch Dashboard — Greeting Service EP3
# Métricas: AWS/EC2 nativas + CI/CD customs + Prometheus
# ──────────────────────────────────────────────────────────
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_ID="i-01e2cf576e5f183ad"
DASHBOARD_NAME="EP3-Greeting-Service-EC2"

cat <<DASHBOARD_JSON > /tmp/ep3-dashboard-body.json
{
  "widgets": [
    {
      "type": "text",
      "x": 0, "y": 0, "width": 24, "height": 2,
      "properties": {
        "markdown": "## EP3 DevOps — Greeting Service Full-Stack (EC2 + Docker Compose)\\n\\n**EC2:** $INSTANCE_ID | **Frontend:** http://100.54.219.189 | **Prometheus:** :8080/actuator/prometheus\\n\\nMétricas nativas AWS/EC2 + CI/CD customs + SonarCloud"
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 2, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", { "stat": "Average", "period": 60, "label": "CPU %" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "REPLACE_REGION",
        "title": "CPU Utilization — EC2 (i-01e2cf576e5f183ad)",
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
          ["AWS/EC2", "NetworkIn", { "stat": "Average", "period": 60, "label": "Network In" }],
          ["AWS/EC2", "NetworkOut", { "stat": "Average", "period": 60, "label": "Network Out" }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "REPLACE_REGION",
        "title": "Network Traffic — EC2 (bytes/s)",
        "yAxis": { "left": { "label": "Bytes", "showUnits": false } },
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
          ["AWS/EC2", "CPUUtilization", { "stat": "Average", "period": 300 }]
        ],
        "view": "singleValue",
        "region": "REPLACE_REGION",
        "title": "CPU Actual (%)",
        "period": 300,
        "stat": "Average",
        "sparkline": true
      }
    },
    {
      "type": "metric",
      "x": 16, "y": 8, "width": 8, "height": 6,
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
      "type": "text",
      "x": 0, "y": 14, "width": 12, "height": 6,
      "properties": {
        "markdown": "### Prometheus Metrics (Backend)\\n\\n| Métrica | Valor |\\n|---|---|\\n| POST 201 (success) | **4,149** |\\n| GET 400 (bad request) | 30 |\\n| GET 500 (server error) | 2 |\\n| JVM Heap Eden | 16 MB |\\n| HikariCP connections | 10 |\\n\\n**Endpoint:** http://100.54.219.189:8080/actuator/prometheus"
      }
    },
    {
      "type": "text",
      "x": 12, "y": 14, "width": 12, "height": 6,
      "properties": {
        "markdown": "### SonarCloud & CI/CD\\n\\n| Métrica | Fuente |\\n|---|---|\\n| Coverage Backend | [SonarCloud](https://sonarcloud.io/dashboard?id=victor99a_Devops-Ev-II) |\\n| Coverage Frontend | Vitest (lcov.info) |\\n| Pipeline | [GitHub Actions](https://github.com/victor99a/Devops-Ev-II/actions) |\\n| Deploy Time | CloudWatch custom |\\n| Smoke Tests | CloudWatch custom |\\n\\n**Pipeline: test-quality → security-scan → build-push → deploy-ec2**"
      }
    },
    {
      "type": "text",
      "x": 0, "y": 20, "width": 24, "height": 2,
      "properties": {
        "markdown": "---\\n**Métricas:** AWS/EC2 (nativas) | **CI/CD:** GreetingService/CICD (custom) | **Prometheus:** :8080/actuator/prometheus | **SonarCloud:** victor99a/victor99a_Devops-Ev-II\\n\\n**Dashboard creado:** $(date)"
      }
    }
  ]
}
DASHBOARD_JSON

sed -i '' "s/REPLACE_REGION/${AWS_REGION}/g" /tmp/ep3-dashboard-body.json

aws cloudwatch put-dashboard \
  --dashboard-name "${DASHBOARD_NAME}" \
  --dashboard-body "file:///tmp/ep3-dashboard-body.json" \
  --region "${AWS_REGION}"

echo "Dashboard: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}"
