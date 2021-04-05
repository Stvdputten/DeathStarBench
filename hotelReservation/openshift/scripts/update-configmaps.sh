#!/bin/bash

cd $(dirname $0)/..

NS="hotel-res"

kubectl create cm configmap-config-json   --from-file=configmaps/config.json  --dry-run --save-config -o yaml -n ${NS} | kubectl apply -f - -n ${NS}

cd - >/dev/null

