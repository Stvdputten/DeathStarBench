#!/bin/bash

NS=hotel-res

cd $(dirname $0)/..

kubectl create namespace ${NS} 2>/dev/null
# kubectl project ${NS}

# kubectl adm policy add-scc-to-user anyuid -z default -n ${NS}
# kubectl adm policy add-scc-to-user privileged -z default -n ${NS}
# kubectl policy add-role-to-user system:image-puller system:serviceaccount:hotel-res:default -n hotel-res
# kubectl policy add-role-to-user system:image-puller kube:admin -n hotel-res

# kubectl policy add-role-to-user system:image-builder kube:admin -n hotel-res
# kubectl policy add-role-to-user registry-viewer kube:admin -n hotel-res
# kubectl policy add-role-to-user registry-editor kube:admin -n hotel-res

./scripts/create-configmaps.sh
for i in *.yaml
do
  kubectl apply -f ${i} -n ${NS} &
done
wait

echo "Finishing in 30 seconds"
sleep 30

kubectl get pods -n ${NS}

cd - >/dev/null

