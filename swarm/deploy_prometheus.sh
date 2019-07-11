#!/bin/bash
set -e

password=Pa22word
URL=prom.dockr.life

# color vars
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

#error checking for client bundle
if [ -z $DOCKER_HOST ]; then
  echo "$RED" " Are you using a client bundle? " "$NORMAL"
  exit 1
fi

echo -n " creating the docker config "
docker config create service.prometheus.conf prometheus.conf > /dev/null 2>&1
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

