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

helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update

cat ../dependencies/fake-gcs.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/" | kubectl apply -f -
kubectl apply -f ../dependencies/postgres.yaml

kubectl rollout status deployment fake-gcs
kubectl rollout status statefulset postgres-statefulset

cat values.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/" | helm upgrade --install mlflow community-charts/mlflow --wait --values -

echo ""
echo "Google Cloud Storage Endpoint: http://gcs.${MINIKUBE_IP}.nip.io"
echo "Mlflow: http://mlflow.${MINIKUBE_IP}.nip.io"
echo ""

echo ""
echo "Please use following commands before run your model taraining file;"
echo "export MLFLOW_TRACKING_URI=http://mlflow.${MINIKUBE_IP}.nip.io"
echo "export STORAGE_EMULATOR_HOST=http://gcs.${MINIKUBE_IP}.nip.io"
echo "export GOOGLE_CLOUD_PROJECT=mlflow"
echo ""