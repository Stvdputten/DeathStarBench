#!/bin/bash

cd $(dirname $0)/../..

kubectl create cm configmap-gen-lua --from-file=configmaps/gen-lua -n media-microsvc

cd -
