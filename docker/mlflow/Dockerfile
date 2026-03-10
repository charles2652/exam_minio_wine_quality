FROM ghcr.io/mlflow/mlflow:v2.10.0 

WORKDIR /mlflow

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD mlflow server \
    --host 0.0.0.0 \
    --port 5000 \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root s3://${MINIO_MLFLOW_BUCKET}/
