FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/usr/local/bin:$PATH"

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*


RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir "setuptools<58.0.0" wheel

COPY requirements.txt .

RUN pip install --no-cache-dir "pyarrow>=14.0.0" --only-binary=:all: && \
    pip install --no-cache-dir --prefer-binary -r requirements.txt

COPY . .

CMD ["python", "main.py"]
