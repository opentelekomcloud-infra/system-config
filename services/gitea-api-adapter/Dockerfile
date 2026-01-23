FROM --platform=linux/amd64 python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY certs/ ./certs/
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 443 8080

CMD ["./entrypoint.sh"]
