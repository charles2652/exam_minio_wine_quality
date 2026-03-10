import sys
import os
from src.pipeline.custom_logger import logger


sys.path.append(os.path.join(os.getcwd(), "src"))


from src.pipeline.pipeline_steps.stage01_data_ingestion import DataIngestionPipeline
from src.pipeline.pipeline_steps.stage02_data_validation import DataValidationTrainingPipeline
from src.pipeline.pipeline_steps.stage03_data_transformation import DataTransformationTrainingPipeline
from src.pipeline.pipeline_steps.stage04_model_trainer import ModelTrainerTrainingPipeline
from src.pipeline.pipeline_steps.stage05_model_evaluation import ModelEvaluationTrainingPipeline

def run_stage(name, stage_class):
    try:
        logger.info(f">>> Etape {name} démarrée <<<")
        pipeline = stage_class()
        pipeline.main()
        logger.info(f">>> Etape {name} terminée avec succès <<<\n{'='*20}")
    except Exception as e:
        logger.exception(f"Échec de l'étape {name}: {e}")
        raise e

if __name__ == "__main__":
    try:
        run_stage("01_INGESTION", DataIngestionPipeline)
        run_stage("02_VALIDATION", DataValidationTrainingPipeline)
        run_stage("03_TRANSFORMATION", DataTransformationTrainingPipeline)
        run_stage("04_ENTRAINEMENT", ModelTrainerTrainingPipeline)
        run_stage("05_EVALUATION", ModelEvaluationTrainingPipeline)

        logger.info(">>>>>> PIPELINE COMPLETE <<<<<<")
    except Exception:
        sys.exit(1)
