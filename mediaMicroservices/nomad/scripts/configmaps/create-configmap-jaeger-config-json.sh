#!/bin/bash

cd $(dirname $0)/../..

kubectl create cm configmap-jaeger-config-json   --from-file=configmaps/jaeger-config.json -n media-microsvc

cd -
