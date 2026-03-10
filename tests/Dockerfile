FROM python:3.10-slim

WORKDIR /app


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir pytest


COPY . .

ENV PYTHONPATH="/app"


CMD ["python3", "-m", "pytest", "-sv", "tests/test_pipeline.py"]
