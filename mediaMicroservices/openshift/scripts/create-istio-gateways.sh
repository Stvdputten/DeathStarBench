#!/bin/bash

NS="media-microsvc"

cd $(dirname $0)/..

kubectl apply -f networking/istio-gateway/mediamicrosvc-gateway.yaml -n ${NS}

cd -
