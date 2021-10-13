#!/bin/bash

cd $(dirname $0)/../..

NS="media-microsvc"

kubectl create cm configmap-gen-lua   --from-file=configmaps/gen-lua --dry-run --save-config -o yaml -n ${NS} | kubectl apply -f - -n ${NS}

cd -
