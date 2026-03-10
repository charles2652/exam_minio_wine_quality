#!/bin/sh


echo "Vérification de la disponibilité du serveur MinIO..."
while ! curl -s http://localhost:9000/minio/health/live; do
    echo "MinIO n'est pas encore prêt... pause de 2 secondes."
    sleep 2
done

echo "Serveur MinIO détecté !"

mc alias set myminio http://localhost:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

if mc ls myminio/"${MINIO_BUCKET}" > /dev/null 2>&1; then
    echo "Le bucket DVC '${MINIO_BUCKET}' existe déjà."
else
    echo "Création du bucket DVC : ${MINIO_BUCKET}"
    mc mb myminio/"${MINIO_BUCKET}"
    mc anonymous set public myminio/"${MINIO_BUCKET}"
fi
if mc ls myminio/"${MINIO_MLFLOW_BUCKET}" > /dev/null 2>&1; then
    echo "Le bucket MLflow '${MINIO_MLFLOW_BUCKET}' existe déjà."
else
    echo "Création du bucket MLflow : ${MINIO_MLFLOW_BUCKET}"
    mc mb myminio/"${MINIO_MLFLOW_BUCKET}"
    mc anonymous set public myminio/"${MINIO_MLFLOW_BUCKET}"
fi
echo "Configuration MinIO terminée avec succès !"
exit 0
