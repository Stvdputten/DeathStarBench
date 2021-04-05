#!/bin/bash

cd $(dirname $0)/..

NS=hotel-res

kubectl create cm configmap-config-json   --from-file=configmaps/config.json  -n ${NS}

cd - >/dev/null
