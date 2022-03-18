## Setup
The docker swarm has been used as template for the kubernetes clusters. The following commands are used to create the kubernetes cluster.

## Notes
No persistent volumes or volume claims have been used in this setup, because the containers in kubernetes provides 8.2GB of disk space already and that is sufficient for the current use case.

The configs.json file not mounted and can be used as reference for building the docker images.
## Kompose
`kompose convert -f docker-swarm.yml` 