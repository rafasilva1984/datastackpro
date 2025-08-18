FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/requirements.txt

# ▼ adiciona trusted-host para contornar o SSL MITM
RUN pip install --no-cache-dir --default-timeout=120 \
    --trusted-host pypi.org --trusted-host files.pythonhosted.org \
    -r /app/requirements.txt

COPY . /app
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
