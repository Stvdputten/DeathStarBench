#!/bin/bash

cd $(dirname $0)/..
NS="social-network"

kubectl create namespace ${NS}
# kubectl adm policy add-scc-to-user anyuid -z default -n ${NS}
# kubectl adm policy add-scc-to-user privileged -z default -n ${NS}

./scripts/create-all-configmap.sh 

# The following script optionally creates local docker images suitable for local customization.
# ./scripts/build-docker-img.sh

for service in *.yaml ;  do
  kubectl apply -f $service -n ${NS}
done

kubectl expose service nginx-thrift -n ${NS}
kubectl expose service jaeger-out -n ${NS}

echo "After all pods are running (oc get pods):"
echo "Follow the instructions in openshift/README.md to configure and run init_social_graph.py to load the dataset."

cd - >/dev/null
