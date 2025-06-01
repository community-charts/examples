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

eval $(minikube docker-env)

N8N_VERSION=1.93.0
docker build --build-arg N8N_VERSION=${N8N_VERSION} -t burakince/n8n-python:${N8N_VERSION} .

export MINIKUBE_IP=$(minikube ip)

helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update

cat values.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/" | sed "s/N8N_VERSION/${N8N_VERSION}/" | helm upgrade --install n8n community-charts/n8n --wait --values -

echo ""
echo "n8n: http://n8n.${MINIKUBE_IP}.nip.io"
echo "n8n-webhook: https://webhook.${MINIKUBE_IP}.nip.io"
echo ""
