#!/bin/sh
# Start HTTP server in background
uvicorn app:app --host 0.0.0.0 --port 8080 &
# Start HTTPS server in foreground with self-signed certs
uvicorn app:app --host 0.0.0.0 --port 443 --ssl-keyfile ./certs/key.pem --ssl-certfile ./certs/cert.pem
