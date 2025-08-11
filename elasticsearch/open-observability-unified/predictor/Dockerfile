FROM python:3.11-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir flask==3.0.3 prometheus-client==0.20.0 requests==2.32.3 numpy==2.0.1

COPY app.py /app/app.py

EXPOSE 8000
CMD ["python", "app.py"]
