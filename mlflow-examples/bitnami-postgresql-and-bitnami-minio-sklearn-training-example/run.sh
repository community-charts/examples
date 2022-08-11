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


helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update

helm upgrade --install mlflow-postgres-postgresql bitnami/postgresql -n airflow -f postgresql-values.yaml --create-namespace --version 11.6.26 --wait

helm upgrade --install minio -n airflow -f minio-values.yaml bitnami/minio --create-namespace --version 11.8.0 --wait

helm upgrade --install mlflow -n airflow -f mlflow-values.yaml community-charts/mlflow --version 0.5.9 --wait 

kubectl delete pod model-training -n airflow --ignore-not-found=true --wait && kubectl apply -f training-pod.yaml -n airflow
