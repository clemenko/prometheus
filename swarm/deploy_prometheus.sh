#!/bin/bash
set -e

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
NODE_TARGETS=""
ENGINE_TARGETS=""
CADVISOR_TARGETS=""
password=Pa22word

URL=app.dockr.life

#error checking for client bundle
if [ -z $DOCKER_HOST ]; then
  echo "$RED" " Are you using a client bundle? " "$NORMAL"
  exit 1
fi

#get node list
echo -n " getting node list "
node_list=$(for NODE in $(docker node ls --format '{{.Hostname}}'); do echo -n "$(docker node inspect --format '{{.Status.Addr}}' "${NODE}") "; done; echo "")

# load images
for node in ${node_list}; do
    NODE_TARGETS="${NODE_TARGETS}'${node}:9100',"
    ENGINE_TARGETS="${ENGINE_TARGETS}'${node}:9323',"
    CADVISOR_TARGETS="${CADVISOR_TARGETS}'${node}:8080',"
done
echo "$GREEN" "[ok]" "$NORMAL"

echo -n " creating prometheus config file "
cat << EOF > service.prometheus.conf
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'nodeexporter'
    scrape_interval: 5s
    static_configs:
      - targets: [${NODE_TARGETS}]

#  - job_name: 'nodeengine'
#    scrape_interval: 5s
#    static_configs:
#      - targets: [${ENGINE_TARGETS}]

  - job_name: 'cadvisor'
    scrape_interval: 5s
    static_configs:
      - targets: [${CADVISOR_TARGETS}]

  - job_name: 'prometheus'
    scrape_interval: 10s
    static_configs:
      - targets: ['localhost:9090']
EOF
echo "$GREEN" "[ok]" "$NORMAL"

if [[ "$(docker config ls | grep service.prometheus.conf | wc -l|sed 's/ //g')" = 1 ]]; then
  echo "$RED" " Updating the current config" "$NORMAL"

  echo -n " creating the new docker config "
  docker config create new.service.prometheus.conf service.prometheus.conf > /dev/null 2>&1
  echo "$GREEN" "[ok]" "$NORMAL"

  docker service update --config-rm service.prometheus.conf --config-add source=new.service.prometheus.conf,target=/etc/prometheus/prometheus.yml prometheus_prometheus

  exit
fi

echo -n " creating the docker config "
docker config create service.prometheus.conf service.prometheus.conf > /dev/null 2>&1
echo "$GREEN" "[ok]" "$NORMAL"

echo -n " deploying stack "
docker stack deploy -c prometheus.yml prometheus
echo "$GREEN" "[ok]" "$NORMAL"

echo -n " waiting for grafana to start "
until $(curl -sIf -o /dev/null http://$URL:3000 ); do printf '.'; sleep 5; done
echo "$GREEN" "[ok]" "$NORMAL"

echo -n " confgiuring grafana through the api "
curl -skX POST  http://admin:$password@$URL:3000/api/datasources -H 'Content-Type: application/json' -d "{ \"name\": \"prometheus\",\"type\": \"prometheus\",\"Access\": \"proxy\",\"url\": \"http://prometheus:9090\",\"basicAuth\": false }" > /dev/null 2>&1

curl -skX POST http://admin:$password@$URL:3000/api/dashboards/import -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -d @cluster.json > /dev/null 2>&1

curl -skX POST http://admin:$password@$URL:3000/api/dashboards/import -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -d @containers.json > /dev/null 2>&1

curl -skX PUT http://admin:$password@$URL:3000/api/org/preferences -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -d '{"theme":"light","homeDashboardId":0,"timezone":""}' > /dev/null 2>&1

echo "$GREEN" "[ok]" "$NORMAL"

echo " grafana's login : admin / Pa22word "

