#!/bin/bash

cd $(dirname $0)/../..

kubectl create cm configmap-nginx-conf   --from-file=configmaps/nginx.conf  -n media-microsvc

cd -
