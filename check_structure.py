import os

# Structure complète du projet
structure = {
    "data": ["processed", "raw", "status.txt"],
    "docker": ["minio", "mlflow", "pipeline"],
    "logs": ["logs.log"],
    "metrics": ["metrics.json"],
    "models": ["model.joblib"],
    "notebooks": ["workflow_steps.ipynb"],
    "src": [
        "__init__.py",
        "app/__init__.py", # Ajouté pour Flask
        "app/app.py",
        "pipeline/__init__.py",
        "pipeline/common_utils.py",
        "pipeline/config.py",
        "pipeline/config.yaml",
        "pipeline/config_manager.py",
        "pipeline/custom_logger.py",
        "pipeline/data_module_def/__init__.py",
        "pipeline/data_module_def/data_ingestion.py",
        "pipeline/data_module_def/data_transformation.py",
        "pipeline/data_module_def/data_validation.py",
        "pipeline/data_module_def/schema.yaml",
        "pipeline/models_module_def/__init__.py",
        "pipeline/models_module_def/model_evaluation.py",
        "pipeline/models_module_def/model_trainer.py",
        "pipeline/models_module_def/params.yaml",
        "pipeline/pipeline_steps/__init__.py",
        "pipeline/pipeline_steps/prediction.py",
        "pipeline/pipeline_steps/stage01_data_ingestion.py",
        "pipeline/pipeline_steps/stage02_data_validation.py",
        "pipeline/pipeline_steps/stage03_data_transformation.py",
        "pipeline/pipeline_steps/stage04_model_trainer.py",
        "pipeline/pipeline_steps/stage05_model_evaluation.py",
    ],
    "templates": ["index.html", "login.html", "register.html", "results.html"],
    "tests": ["__init__.py", "Dockerfile", "requirements.txt", "test_pipeline.py"],
    "docker-compose.yml": None, # Attention : ton fichier s'appelle .yml dans le ll
    "Makefile": None,
    "requirements.txt": None,
    "README.md": None,
    ".gitignore": None,
    ".dvcignore": None,
}

def check_and_fix(base_path="."):
    print("🚀 Vérification de la structure du projet...\n")
    for folder, contents in structure.items():
        # 1. Gérer les fichiers à la racine
        if contents is None:
            if not os.path.exists(os.path.join(base_path, folder)):
                print(f"❌ Manquant : Fichier racine {folder}")
            else:
                print(f"✅ Présent : {folder}")
            continue

        # 2. Gérer les dossiers
        folder_path = os.path.join(base_path, folder)
        if not os.path.exists(folder_path):
            os.makedirs(folder_path)
            print(f"📁 Créé le dossier : {folder}")
        
        # 3. Gérer le contenu du dossier
        for item in contents:
            item_path = os.path.join(folder_path, item)
            # Si l'item contient un '/', c'est un sous-dossier (ex: app/app.py)
            if "/" in item:
                os.makedirs(os.path.dirname(item_path), exist_ok=True)
            
            if not os.path.exists(item_path):
                with open(item_path, "w") as f:
                    f.write("")
                print(f"📝 Créé le fichier manquant : {item_path}")
            else:
                print(f"✅ Présent : {item_path}")

if __name__ == "__main__":
    check_and_fix()
    print("\n✨ Structure vérifiée et corrigée.")
