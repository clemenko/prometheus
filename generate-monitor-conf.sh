#!/bin/bash
set -e
NODES=$@

if [ -z "${NODES}" ]; then
    echo "Usage: $0 <node> [node] [node]"
    exit 1
fi

NODE_TARGETS=""
ENGINE_TARGETS=""
CADVISOR_TARGETS=""

# load images
for node in ${NODES}; do
    NODE_TARGETS="${NODE_TARGETS}'${node}:9100',"
    ENGINE_TARGETS="${ENGINE_TARGETS}'${node}:9323',"
    CADVISOR_TARGETS="${CADVISOR_TARGETS}'${node}:8080',"
done

cat << EOF | docker config create service.prometheus.conf -
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'nodeexporter'
    scrape_interval: 5s
    static_configs:
      - targets: [${NODE_TARGETS}]

  - job_name: 'nodeengine'
    scrape_interval: 5s
    static_configs:
      - targets: [${ENGINE_TARGETS}]

  - job_name: 'cadvisor'
    scrape_interval: 5s
    static_configs:
      - targets: [${CADVISOR_TARGETS}]

  - job_name: 'prometheus'
    scrape_interval: 10s
    static_configs:
      - targets: ['localhost:9090']
EOF

docker stack deploy -c monitor.yml monitor

sleep 30

curl -skX POST  http://admin:grafana@app.dockr.life:3000/api/datasources -H 'Content-Type: application/json' -d "{ \"name\": \"prometheus\",\"type\": \"prometheus\",\"Access\": \"proxy\",\"url\": \"http://prometheus:9090\",\"basicAuth\": false }" > /dev/null 2>&1

curl -skX POST http://admin:grafana@app.dockr.life:3000/api/dashboards/import -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -d @cluster.json > /dev/null 2>&1

curl -skX POST http://admin:grafana@app.dockr.life:3000/api/dashboards/import -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -d @containers.json > /dev/null 2>&1
