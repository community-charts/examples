#!/bin/bash

helm delete mlflow-postgres-postgresql -n airflow
kubectl delete pvc -l "app.kubernetes.io/name=postgresql" -n airflow

helm delete minio -n airflow
helm delete mlflow -n airflow
