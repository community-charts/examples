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
check_command curl
check_command jq

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

helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update

kubectl apply -f ../dependencies/postgres.yaml
kubectl rollout status statefulset postgres-statefulset

USERNAME="testuser"
PASSWORD="password"

echo ""
cat gitea-values.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/" | helm upgrade --install gitea gitea-charts/gitea --version 5.0.4 --wait --values -
echo ""

while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' gitea.${MINIKUBE_IP}.nip.io:80)" != "200" ]]; do sleep 5; done


TOKEN_COUNT=$(curl --silent --request GET --url http://${USERNAME}:${PASSWORD}@gitea.${MINIKUBE_IP}.nip.io/api/v1/users/${USERNAME}/tokens | jq '. | length')

if (( ${TOKEN_COUNT} == 0 )); then
  TOKEN=$(curl -XPOST -H "Content-Type: application/json" -k -d '{"name":"machine-access"}' -u ${USERNAME}:${PASSWORD} http://gitea.${MINIKUBE_IP}.nip.io/api/v1/users/${USERNAME}/tokens | jq --raw-output .sha1)
  PAYLOAD="{\"name\":\"drone\",\"redirect_uris\":[\"http://drone.${MINIKUBE_IP}.nip.io/login\"]}"
  curl -XPOST -H "Content-Type: application/json" -H "Authorization: token ${TOKEN}" -d "${PAYLOAD}" http://gitea.${MINIKUBE_IP}.nip.io/api/v1/user/applications/oauth2 > client_secrets
fi

echo ""
cat drone-values.yaml | sed "s/MINIKUBE_IP/$(minikube ip)/g" | helm upgrade --install drone community-charts/drone \
  --set server.secrets.DRONE_GITEA_CLIENT_ID=$(cat ./client_secrets | jq --raw-output .client_id) \
  --set server.secrets.DRONE_GITEA_CLIENT_SECRET=$(cat ./client_secrets | jq --raw-output .client_secret) \
  --wait --values -
echo ""

echo ""
echo "Gitea URL: http://gitea.${MINIKUBE_IP}.nip.io"
echo "Gitea Swagger URL: http://gitea.${MINIKUBE_IP}.nip.io/api/swagger"
echo "Gitea username: testuser"
echo "Gitea password: password"
echo "Drone URL: http://drone.${MINIKUBE_IP}.nip.io"
echo ""
