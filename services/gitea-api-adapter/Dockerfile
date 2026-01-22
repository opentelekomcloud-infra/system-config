FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY certs/ ./certs/

EXPOSE 443

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "443", "--ssl-keyfile", "./certs/key.pem", "--ssl-certfile", "./certs/cert.pem"]
