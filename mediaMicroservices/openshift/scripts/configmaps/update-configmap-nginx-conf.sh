#!/bin/bash

cd $(dirname $0)/../..

NS="media-microsvc"

kubectl create cm configmap-nginx-conf   --from-file=configmaps/nginx.conf  --dry-run --save-config -o yaml -n ${NS} | kubectl apply -f - -n ${NS}

cd -
