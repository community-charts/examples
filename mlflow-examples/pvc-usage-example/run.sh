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
KUBE_STATUS=`minikube status | grep 'host:' | head -1 | awk -F': ' '{print $2}'`
if [[ -z ${KUBE_STATUS} || ${KUBE_STATUS} == "Stopped" ]]; then
  minikube start --vm=true
  # If vm flag doesn't work in your system,
  # you can install hyperkit with `brew install hyperkit` command
  # and run the minikube with the following command:
  # `minikube start --driver=hyperkit`
fi
# wait for kubectl to be up
for i in {1..150}; do # timeout for 5 minutes
  kubectl get pods &> /dev/null
  if [ $? -ne 1 ]; then
    break
  fi
  sleep 2
done

minikube addons enable ingress

export MINIKUBE_IP=$(minikube ip)

helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update

kubectl apply -f pvc.yaml
cat values.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/" | helm upgrade --install mlflow community-charts/mlflow --wait --values -
