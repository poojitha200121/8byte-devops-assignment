#!/usr/bin/env bash
set -euo pipefail

MONITORING_DIR="/opt/monitoring"
GRAFANA_DIR="${MONITORING_DIR}/grafana"

# Basic monitoring setup for the Petclinic EC2 instance.
# Prometheus runs on host port 9091 and Grafana runs on host port 3000.

mkdir -p "${MONITORING_DIR}"
mkdir -p "${GRAFANA_DIR}/provisioning/datasources"

cat > "${MONITORING_DIR}/prometheus.yml" <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: petclinic
    metrics_path: /actuator/prometheus
    static_configs:
      - targets:
          - host.docker.internal:9090
EOF

cat > "${GRAFANA_DIR}/provisioning/datasources/prometheus.yml" <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

docker network create monitoring 2>/dev/null || true

docker volume create prometheus-storage >/dev/null
docker rm -f prometheus 2>/dev/null || true
docker run -d --name prometheus \
  --restart unless-stopped \
  --network monitoring \
  --add-host=host.docker.internal:host-gateway \
  -p 9091:9090 \
  -v prometheus-storage:/prometheus \
  -v "${MONITORING_DIR}/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  prom/prometheus

docker volume create grafana-storage >/dev/null
docker rm -f grafana 2>/dev/null || true
docker run -d --name grafana \
  --restart unless-stopped \
  --network monitoring \
  -p 3000:3000 \
  -v grafana-storage:/var/lib/grafana \
  -v "${GRAFANA_DIR}/provisioning:/etc/grafana/provisioning:ro" \
  grafana/grafana

# Container creation is not enough: wait until both HTTP services respond.
curl --fail --silent --show-error --retry 30 --retry-delay 2 \
  --retry-connrefused --connect-timeout 2 --max-time 5 \
  http://localhost:9091/-/ready
curl --fail --silent --show-error --retry 30 --retry-delay 2 \
  --retry-connrefused --connect-timeout 2 --max-time 5 \
  http://localhost:3000/api/health

echo "Monitoring setup completed."
echo "Prometheus: http://<EC2_PUBLIC_IP>:9091"
echo "Grafana:    http://<EC2_PUBLIC_IP>:3000"
