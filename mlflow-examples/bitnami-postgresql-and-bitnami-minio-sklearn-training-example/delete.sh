#!/bin/bash

helm delete mlflow-postgres-postgresql -n mlflow
kubectl delete pvc -l "app.kubernetes.io/name=postgresql" -n mlflow

helm delete minio -n mlflow
helm delete mlflow -n mlflow
