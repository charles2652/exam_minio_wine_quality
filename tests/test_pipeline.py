import os
import pytest
from minio import Minio
import mlflow
from mlflow.tracking import MlflowClient

MINIO_PARAMS = {
    "endpoint": os.getenv("MINIO_ENDPOINT"),
    "access_key": os.getenv("MINIO_ACCESS_KEY"),
    "secret_key": os.getenv("MINIO_SECRET_KEY"),
    "secure": False
}
DATA_BUCKET = os.getenv("MINIO_DATA_BUCKET")
MLFLOW_BUCKET = os.getenv("MINIO_MLFLOW_BUCKET")
MLFLOW_URI = os.getenv("MLFLOW_TRACKING_URI")

def print_step(msg):
    print(f"\n{'='*10} {msg} {'='*10}")


def test_minio_buckets_exist():
    print_step("🔍 TEST:  Est-ce que les buckets dvc-storage et mlflow-artifacts existent ?")
    try:
        client = Minio(**MINIO_PARAMS)
        for b in [DATA_BUCKET, MLFLOW_BUCKET]:
            exists = client.bucket_exists(b)
            status = "✅" if exists else "❌"
            print(f"{status} Bucket '{b}'")
            assert exists, f"Le bucket {b} n'existe pas "
    except Exception as e:
        pytest.fail(f"💥 Erreur connexion MinIO : {e}")

def test_mlflow_experiment_tracked():
    print_step("🔍 TEST: Est-ce que les expériences de la pipeline dvc sont bien trackées par mlflow ?")
    try:
        mlflow.set_tracking_uri(MLFLOW_URI)
        client = MlflowClient()
        exps = client.search_experiments()
        count = len(exps)
        print(f"✅ {count} expérience(s) trouvée(s) sur {MLFLOW_URI}")
        assert count > 0, "Aucune expérience MLflow détectée."
    except Exception as e:
        pytest.fail(f"💥 Erreur connexion MLflow : {e}")

def test_dvc_artifacts_in_minio():
    print_step("🔍 TEST: Est-ce que le bucket dvc-storage contient les fichiers attendus ?")
    try:
        client = Minio(**MINIO_PARAMS)
        objs = list(client.list_objects(DATA_BUCKET, prefix='files/md5/', recursive=True))
        print(f"✅ {len(objs)} fichiers DVC détectés dans {DATA_BUCKET}")
        assert len(objs) > 0, "Le bucket DVC est totalement vide."
    except Exception as e:
        pytest.fail(f"💥 Erreur accès données DVC : {e}")

def test_mlflow_artifacts_in_minio():
    print_step("🔍 TEST: Est-ce que le bucket mlflow-artifacts contient les fichiers attendus ?")
    try:
        client = Minio(**MINIO_PARAMS)
        objs = list(client.list_objects(MLFLOW_BUCKET, recursive=True))
        print(f"✅ {len(objs)} artefacts MLflow  stockés.")
        assert len(objs) > 0, "Le bucket des artefacts MLflow est vide."
    except Exception as e:
        pytest.fail(f"💥 Erreur accès artefacts MLflow : {e}")
