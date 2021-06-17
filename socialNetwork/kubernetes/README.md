# Social Network Microservices on Kubernetes

## Pre-requirements

- A running Kubernetes cluster is needed.
- The user should be authenticated to this cluster e.g., `kubectl login`
- Pre-requirements mentioned [here](https://github.com/delimitrou/DeathStarBench/blob/master/socialNetwork/README.md) should be met.

## Running the social network application on Kubernetes

### (Optional) Using k3d

Don't forget to disable your VPN. Start the k3d cluster and import the local images:
- `k3d cluster create k3d-DeathStarBench --api-port 6433 --servers 1 --agents 3 --volume /path/to/DeathStarBench:/root/DeathStarBench@all --port '8080:80@loadbalancer'`
- `k3d image import -c k3d-DeathStarBench memcached:latest mongo:latest redis:latest rabbitmq:latest jaegertracing/all-in-one:latest yg397/media-frontend:xenial yg397/openresty-thrift:xenial yg397/social-network-microservices:latest`
- `k3d cluster delete k3d-DeathStarBench`
### Before you start

Get the IP address for the DNS resolver: `kubectl describe dns.operator/default`. Then set it in files such as:
- `<path-of-repo>/socialNetwork/openshift/nginx-web-server-config/nginx.conf`
- `<path-of-repo>/socialNetwork/openshift/media-frontend-config/nginx.conf`

### Deploy services

Run the script `<path-of-repo>/socialNetwork/openshift/scripts/deploy-all-services-and-configurations.sh`

### Using `ubuntu-client` as an "on-cluster" client

After customization, If you are running "on-cluster" copy necessary files to `ubuntu-client`, and then log into `ubuntu-client` to continue:
  - `ubuntuclient=$(kubectl -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")`
  - `kubectl cp <path-of-repo> social-network/"${ubuntuclient}":/root`
    - e.g., `kubectl cp /root/DeathStarBench social-network/"${ubuntuclient}":/root`
  - `kubectl rsh deployment/ubuntu-client`


### Register users and construct social graphs

- If using an off-cluster client:
  - Use `kubectl -n social-network get svc nginx-thrift` to get the cluster-ip.
  - Paste the cluster ip at `<path-of-repo>/socialNetwork/scripts/init_social_graph.py:72`
- If using an on-cluster client:
  - Use `nginx-thrift.social-network.svc.cluster.local` as cluster-ip and paste it at `<path-of-repo>/socialNetwork/scripts/init_social_graph.py:72`
- Register users and construct social graph by running `cd <path-of-repo>/socialNetwork && python3 scripts/init_social_graph.py`.
  This will initialize a social graph based on [Reed98 Facebook Networks](http://networkrepository.com/socfb-Reed98.php), with 962 users and 18.8K social graph edges. 

### Running HTTP workload generator

There are three type of applications in the workload: compose post, write home timeline, and read home timeline.
The applications run independently and each one has a different workflow, using different micro-services.

First, make sure that the `wrk` command has been properly built for your platform:
```bash
cd <path-of-repo>/socialNetwork/wrk2
make clean
make
```

For all load generating commands below, it should be possible to use `nginx-thrift.social-network.svc.cluster.local:8080` for `cluster-ip`.

#### Compose posts

```bash
cd <path-of-repo>/socialNetwork/wrk2
./wrk -D exp -t <num-threads> -c <num-conns> -d <duration> -L -s ./scripts/social-network/compose-post.lua http://<cluster-ip>/wrk2-api/post/compose -R <reqs-per-sec>
```

#### Read home timelines

```bash
cd <path-of-repo>/socialNetwork/wrk2
./wrk -D exp -t <num-threads> -c <num-conns> -d <duration> -L -s ./scripts/social-network/read-home-timeline.lua http://<cluster-ip>/wrk2-api/home-timeline/read -R <reqs-per-sec>
```

#### Read user timelines

```bash
cd <path-of-repo>/socialNetwork/wrk2
./wrk -D exp -t <num-threads> -c <num-conns> -d <duration> -L -s ./scripts/social-network/read-user-timeline.lua http://<cluster-ip>/wrk2-api/user-timeline/read -R <reqs-per-sec>
```


#### View Jaeger traces

Use `kubectl -n social-network get svc jaeger-out` to get the NodePort of jaeger service.

 View Jaeger traces by accessing `http://<node-ip>:<NodePort>` 


### OpenShift SCC

Original containers are expected to run as root, but OpenShift does not permit it as a default policy. 
As a workaround for simplicity, we can relax security policy by adding several SCCs to each project.

```
$ kubectl adm policy add-scc-to-user anyuid -z default
$ kubectl adm policy add-scc-to-user privileged -z default
```


### Local image customization

If local image customization is needed, then the script
`<path-of-repo>/socialNetwork/openshift/scripts/build-docker-img.sh`
can be used to create them. In this case the relevant yaml files will need to
be edited to refer to the new images.
e.g., `image: image-registry.openshift-image-registry.svc:5000/social-network/social-network-microservices:openshift`