#!/bin/bash

N=media-microsvc

cd $(dirname $0)/../..

kubectl create cm configmap-lua-scripts   --from-file=configmaps/lua-scripts -n ${N}

for i in cast-info movie movie-info plot review user
do
  kubectl create cm configmap-lua-scripts-${i} --from-file=configmaps/lua-scripts/wrk2-api/${i} -n ${N}
done

cd -
