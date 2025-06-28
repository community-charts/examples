#!/bin/bash

function check_command {
  COMMAND_PARAMETER=$1

  if ! command -v ${COMMAND_PARAMETER} &> /dev/null
  then
    echo "Command '${COMMAND_PARAMETER}' could not be found"
    exit
  fi
}

check_command kubectl
check_command minikube
check_command helm

echo "Starting minikube..."
KUBE_STATUS=`minikube status -p multinode-minikube | grep 'host:' | head -1 | awk -F': ' '{print $2}'`
if [[ -z ${KUBE_STATUS} || ${KUBE_STATUS} == "Stopped" ]]; then
  minikube start --cpus 2 --memory 2048 --nodes 3 -p multinode-minikube
fi
# wait for kubectl to be up
for i in {1..150}; do # timeout for 5 minutes
  kubectl get pods &> /dev/null
  if [ $? -ne 1 ]; then
    break
  fi
  sleep 2
done

minikube profile list

helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update

helm upgrade --install n8n community-charts/n8n --values values.yaml --create-namespace --namespace n8n --wait

echo ""
echo "Run the following command to access n8n from http://localhost:8080"
echo "kubectl port-forward svc/n8n 8080:5678 -n n8n"
echo ""
