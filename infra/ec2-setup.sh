#!/bin/bash
# ──────────────────────────────────────────────────────────────
# EC2 Setup Script — Greeting Service EP3 DevOps
# User Data para Amazon Linux 2023
# ──────────────────────────────────────────────────────────────
set -euo pipefail

echo "=== Greeting Service EP3 — EC2 Provisioning ==="
exec > >(tee /var/log/user-data.log) 2>&1

# ── 1. Actualizar sistema ──────────────────────────────
echo "[1/6] Updating system..."
yum update -y

# ── 2. Instalar Docker ─────────────────────────────────
echo "[2/6] Installing Docker..."
yum install -y docker git
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ── 3. Instalar Docker Compose standalone ──────────────
echo "[3/6] Installing Docker Compose..."
curl -sL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# ── 4. Clonar repositorio ──────────────────────────────
echo "[4/6] Cloning repository..."
su - ec2-user -c "
  cd /home/ec2-user
  git clone https://github.com/victor99a/Devops-Ev-II.git
"

# ── 5. Levantar servicios con Docker Compose ────────────
echo "[5/6] Starting services..."
su - ec2-user -c "
  cd /home/ec2-user/Devops-Ev-II
  docker compose up -d --build
"

# ── 6. Instalar CloudWatch Agent ───────────────────────
echo "[6/6] Installing CloudWatch Agent..."
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/greeting-service/ec2/system",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/docker",
            "log_group_name": "/greeting-service/ec2/docker",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "totalcpu": true
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "=== Provisioning complete ==="
echo "Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Backend:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
