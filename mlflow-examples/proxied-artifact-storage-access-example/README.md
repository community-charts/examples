# MLflow Tracking Server enabled with proxied artifact storage access example

This example simulates the proxied artifact storage access. Please review the [values.yaml](values.yaml) file. And you can find more information from [here](https://www.mlflow.org/docs/latest/tracking.html#scenario-5-mlflow-tracking-server-enabled-with-proxied-artifact-storage-access).

## Manual Test Preperation

```
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt
```

## Running Tests

```
pytest test_proxy.py
```
