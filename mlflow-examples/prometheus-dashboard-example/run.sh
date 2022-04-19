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

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update

cat prometheus-values.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/" | helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace --version 34.10.0 --wait --values -

cat mlflow-values.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/" | helm upgrade --install mlflow community-charts/mlflow --wait --values -

echo ""
echo "Grafana URL: http://grafana.${MINIKUBE_IP}.nip.io"
echo "Grafana username: admin"
echo "Grafana password: admin"
echo "Mlflow URL: http://mlflow.${MINIKUBE_IP}.nip.io"
echo ""
