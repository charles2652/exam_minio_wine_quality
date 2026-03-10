# Variables
COMPOSE=docker compose
VENV_BIN=./env/bin
PUBLIC_IP=52.31.94.17

.PHONY: all help build up down pipeline tests validate clean dvc-clean setup-minio init-local report

help:
	@echo "--- COMMANDES PRINCIPALES ---"
	@echo "  make all      : Nettoie tout et relance la chaîne complète"
	@echo "  make pipeline : Orchestre l'exécution DVC et le tracking MLflow"
	@echo "  make tests    : Lance les 4 tests pytest obligatoires"
	@echo "  make report   : Affiche le diagnostic de santé du projet"
	@echo "  make clean    : Supprime conteneurs, volumes et caches"

all: clean init-local pipeline

init-local:
	@if [ ! -d "env" ]; then \
		python3 -m venv env && \
		$(VENV_BIN)/pip install --upgrade pip "setuptools<70.0.0" wheel && \
		$(VENV_BIN)/pip install -r requirements.txt; \
	fi

setup-minio:
	@echo "--- Démarrage Infrastructure (MinIO + MLflow) ---"
	$(COMPOSE) up -d minio mlflow
	@echo "--- Attente des services... ---"
	@sleep 10
	$(COMPOSE) exec -T minio mc alias set myminio http://localhost:9000 admin password123
	$(COMPOSE) exec -T minio mc mb --ignore-existing myminio/dvc-storage
	$(COMPOSE) exec -T minio mc mb --ignore-existing myminio/mlflow-artifacts

pipeline: build setup-minio
	@echo "--- Exécution du Pipeline DVC (Entraînement & Tracking) ---"
	$(COMPOSE) run --rm pipeline dvc repro
	@$(MAKE) tests

tests:
	@echo "--- 1. Synchronisation DVC vers MinIO ---"
	@AWS_ACCESS_KEY_ID=admin AWS_SECRET_ACCESS_KEY=password123 \
	MLFLOW_S3_ENDPOINT_URL=http://$(PUBLIC_IP):9000 \
	$(VENV_BIN)/dvc push
	@echo "--- 2. Exécution des 4 tests Pytest obligatoires ---"
	@$(COMPOSE) run --rm tests python3 -m pytest -p no:warnings -sv tests/test_pipeline.py

diag:
	@echo "========================================================================"
	@echo "                   DIAGNOSTIC SYSTÈME & INFRASTRUCTURE                  "
	@echo "========================================================================"
	@echo "--- État du Disque & RAM ---"
	@df -h / | awk 'NR==1 || NR==2'
	@echo ""
	@free -h
	@echo ""
	@echo "--- État des Conteneurs Docker ---"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "--- Adresses d'Accès Réseau ---"
	@echo "  [INTERNE DOCKER] (Pour le code/pipeline)"
	@echo "  - MLflow Tracking : http://mlflow:5000"
	@echo "  - MinIO API       : http://minio:9000"
	@echo ""
	@echo "  [EXTERNE AWS] (Pour le navigateur/DVC local)"
	@echo "  - MLflow UI       : http://$(PUBLIC_IP):5000"
	@echo "  - MinIO Console   : http://$(PUBLIC_IP):9001"
	@echo "  - DVC/S3 Remote   : http://$(PUBLIC_IP):9000"
	@echo "========================================================================"
	@echo "--- Cache de Build Docker ---"
	@docker system df


down:
	@echo "--- 🔽 Arrêt propre des services ---"
	$(COMPOSE) down --remove-orphans --timeout 10
	@echo "✅ Services arrêtés."


clean: dvc-clean
	@echo "--- 🛑 Arrêt et suppression des conteneurs/volumes ---"
	$(COMPOSE) down -v --remove-orphans
	@echo "--- 🧹 Nettoyage des fichiers de travail locaux ---"
	# Supprime les logs, le cache python, les résultats MLflow locaux et les modèles
	rm -rf logs/*.log mlruns/ models/*.joblib metrics/*.json .pytest_cache
	sudo find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "--- 🚀 Libération AGRESSIVE de l'espace Docker ---"
	# -a supprime toutes les images inutilisées, pas seulement les 'dangling'
	docker system prune -a -f --volumes
	@echo "--- 🧱 Nettoyage du cache de build ---"
	docker builder prune -a -f
	@echo "✅ Espace disque optimisé au maximum."
