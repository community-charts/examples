from platform import python_version
import subprocess
import requests
import mlflow
import cloudpickle
from mlflow.tracking.client import MlflowClient


class MyModel(mlflow.pyfunc.PythonModel):
    def __init__(self, value):
        self.value = value
        super().__init__()

    def predict(self, context, model_input):
        return "Hello World"

training_params = {"value": 5}
my_model = MyModel(**training_params)
conda_env = {
    "channels": ["defaults", "conda-forge"],
    "dependencies": [
        "python={}".format(python_version()),
        "pip",
        {"pip": ["cloudpickle={}".format(cloudpickle.__version__)]},
    ],
    "name": "mlflow-env",
}

def test_proxied_artifact_storage_access_via_api():
    minikube_ip = subprocess.check_output(["minikube", "ip"]).strip().decode("utf-8")

    base_url = f"http://mlflow.{minikube_ip}.nip.io"

    experiment_name = "aws-cloud-experiment"
    model_name = "test-aws-model"
    stage_name = "Staging"
    mlflow.set_tracking_uri(base_url)
    mlflow.set_experiment(experiment_name)
    experiment = mlflow.get_experiment_by_name(experiment_name)

    with mlflow.start_run(experiment_id=experiment.experiment_id) as run:
        mlflow.log_params(training_params)
        mlflow.pyfunc.log_model("model", conda_env=conda_env, python_model=my_model)
        model_uri = f"runs:/{run.info.run_id}/model"
        model_details = mlflow.register_model(model_uri, model_name)

        client = MlflowClient()
        client.transition_model_version_stage(
            name=model_details.name,
            version=model_details.version,
            stage=stage_name,
        )

    params = {"name": model_name, "stages": stage_name}
    latest_version_url = (
        f"{base_url}/api/2.0/preview/mlflow/registered-models/get-latest-versions"
    )
    r = requests.get(url=latest_version_url, params=params)

    assert "READY" == r.json()["model_versions"][0]["status"]
