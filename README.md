# Prometheus Grafana Swarm deploy-orama
The intent of this repo is to have a simple way to deploy Prometheus and Grafana with dashboards on Swarm.
This is a BASIC implementation of Prometheus and Grafana.

## Included files :
* cluster.json - Grafana Cluster Dashboard
* containers.json - Grafana Containers Dashboard
* prometheus.yml - compose file
* deploy_prometheus.sh - Simple script to deploy.

## Moving parts :
* Prometheus node-exporter, global, provides OS metrics.
* Cadvisor, global, provides container metrics.
* Prometheus, single, collects all the metrics, gets configured with the `docker config`.
* Grafana, single, dashboarding for prometheus.

## Deployment/Usage
To deploy you will need a swarm cluster and a docker engine. Ideally you would use a client bundle pointed at a UCP.
`git clone https://github.com/clemenko/prometheus_swarm.git`

Source the client bundle, `. ./env.sh`.

And run the deploy script...
Example :
`./deploy_prometheus.sh`
Right now the script does not allow for updating.

You can ignore the deploy labels in the prometheus.yml. They are for interlock 2.0.
```
com.docker.lb.hosts: grafana.dockr.life
com.docker.lb.port: 3000
```


## Future
Currently Docker engine provides a prometheus endpoint. This is currently experimental, but I have hopes that it can replace cadvisor. If you want to play with it you can enable it at each engine with :
```
echo -e "{ \"storage-driver\": \"overlay2\", \n  \"storage-opts\": [\"overlay2.override_kernel_check=true\"], \n \"metrics-addr\" : \"0.0.0.0:9323\", \n \"experimental\" : true \n}" > /etc/docker/daemon.json; systemctl restart docker
```
Idealy this will be done when bootstrapping the node.
