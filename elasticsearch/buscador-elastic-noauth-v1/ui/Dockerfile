FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt /app/requirements.txt

# ▼ adiciona trusted-host para contornar o SSL MITM
RUN pip install --no-cache-dir --default-timeout=120 \
    --trusted-host pypi.org --trusted-host files.pythonhosted.org \
    -r /app/requirements.txt

COPY . /app
EXPOSE 8501
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
