#!/bin/bash

cd $(dirname $0)/..

NS="media-microsvc"

kubectl create namespace ${NS}

for service in *service.yaml
do
  kubectl apply -f $service --namespace ${NS}
done

cd -
