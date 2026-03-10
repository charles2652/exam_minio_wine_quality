#!/bin/bash

# --- CONFIGURATION ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PUBLIC_IP="52.31.94.17"
ERRORS=0
TOTAL_TESTS=0

clear
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}       VALIDATION DES ACCÈS & FLUX DU PIPELINE        ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Fonction pour afficher le statut OK/KO
print_status() {
    ((TOTAL_TESTS++))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}  [OK]  ${NC} $2"
    else
        echo -e "${RED}  [KO]  ${NC} $2"
        ((ERRORS++))
    fi
}

# --- ÉTAPE 1 : ACCÈS EXTERNES (WEB UI) ---
echo -e "\n${YELLOW}[1/5] Vérification des accès Web (Public)...${NC}"
curl -s -o /dev/null --max-time 3 http://${PUBLIC_IP}:5000
print_status $? "Accès externe MLflow UI (http://${PUBLIC_IP}:5000)"
curl -s -o /dev/null --max-time 3 http://${PUBLIC_IP}:9001
print_status $? "Accès externe MinIO Console (http://${PUBLIC_IP}:9001)"

# --- ÉTAPE 2 : CONNECTIVITÉ INTERNE DU PIPELINE ---
echo -e "\n${YELLOW}[2/5] Tests de communication interne (Pipeline)...${NC}"

# Test DNS interne vers MLflow
docker compose run --rm pipeline curl -s -o /dev/null --max-time 2 http://mlflow:5000
print_status $? "Pipeline -> MLflow (Réseau Docker)"

# Test DNS interne vers MinIO API
docker compose run --rm pipeline curl -s -o /dev/null --max-time 2 http://minio:9000/minio/health/live
print_status $? "Pipeline -> MinIO API (Réseau Docker)"

# --- ÉTAPE 3 : VARIABLES D'ENVIRONNEMENT ---
echo -e "\n${YELLOW}[3/5] Validation des variables d'environnement...${NC}"

# Vérifier si AWS_ACCESS_KEY_ID est présent dans le container pipeline
docker compose run --rm pipeline env | grep -q "AWS_ACCESS_KEY_ID"
print_status $? "Injection des credentials AWS S3 (Sécure)"

# Vérifier l'URI de tracking MLflow
docker compose run --rm pipeline env | grep "MLFLOW_TRACKING_URI" | grep -q "http://mlflow:5000"
print_status $? "Configuration MLFLOW_TRACKING_URI"

# --- ÉTAPE 4 : DÉPENDANCES & MODULES ---
echo -e "\n${YELLOW}[4/5] Intégrité de l'image Pipeline...${NC}"

# Test de l'import des modules ML
docker compose run --rm pipeline python3 -c "import pandas; import mlflow; import sklearn" 2>/dev/null
print_status $? "Librairies ML (Pandas, Scikit-learn, MLflow)"

# Test du module critique pkg_resources
docker compose run --rm pipeline python3 -c "import pkg_resources" 2>/dev/null
print_status $? "Module pkg_resources (Compatibilité MLflow)"

# --- ÉTAPE 5 : EXÉCUTION DES TESTS UNITAIRES ---
echo -e "\n${YELLOW}[5/5] Exécution des tests (Répertoire tests/)...${NC}"
echo -e "${CYAN}------------------------------------------------------${NC}"
docker compose run --rm tests pytest -v --disable-warnings tests/
PYTEST_RES=$?
echo -e "${CYAN}------------------------------------------------------${NC}"
print_status $PYTEST_RES "Suite de tests unitaires (Logic & Buckets)"

# --- BILAN FINAL ---
echo -e "\n${BLUE}======================================================${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}          ✅ TOUT EST PRÊT POUR L'ENTRAÎNEMENT         ${NC}"
    echo -e "${CYAN}  Utilisez 'make validate' pour lancer la pipeline.    ${NC}"
else
    echo -e "${RED}          ❌ ERREUR DETECTÉE : $ERRORS KO(S)            ${NC}"
    echo -e "${YELLOW}   Vérifiez vos Security Groups ou votre fichier .env   ${NC}"
fi
echo -e "${BLUE}======================================================${NC}"
echo -e "${CYAN}  MLflow : http://${PUBLIC_IP}:5000${NC}"
echo -e "${CYAN}  MinIO  : http://${PUBLIC_IP}:9001 (admin/password123)${NC}"
echo -e "${BLUE}======================================================${NC}"

exit $ERRORS
