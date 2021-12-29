#!/bin/bash

NS=hotel-res

cd $(dirname $0)/..

kubectl create namespace ${NS} 2>/dev/null
# kubectl project ${NS}

# create persistent volumes
for i in *-pv.yaml
do
  kubectl apply -f ${i} -n ${NS} &
done

# create persistent volume claims
for i in *-pvc.yaml
do
  kubectl apply -f ${i} -n ${NS} &
done

./scripts/create-configmaps.sh
for i in *.yaml
do
  kubectl apply -f ${i} -n ${NS} &
done
wait

echo "Finishing in 30 seconds"
# sleep 30
# sleep 5

# kubectl get pods -n ${NS}
kubectl get pv -n ${NS}
kubectl get pvc -n ${NS}

cd - >/dev/null

