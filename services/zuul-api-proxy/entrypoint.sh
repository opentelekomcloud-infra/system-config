#!/bin/sh
set -e

# Start mitmproxy in background to generate certs
mitmdump --mode regular@8080 --ssl-insecure -s /app/router.py --set upstream_cert=false &
MITM_PID=$!

# Wait for cert to be generated (max 10 seconds)
echo "Waiting for mitmproxy to generate CA certificate..."
for i in $(seq 1 10); do
    if [ -f /root/.mitmproxy/mitmproxy-ca-cert.pem ]; then
        echo "CA certificate found, copying to shared volume..."
        cp /root/.mitmproxy/mitmproxy-ca-cert.pem /mitmproxy-ca/
        echo "CA certificate copied successfully"
        break
    fi
    sleep 1
done

# Wait for the background process
wait $MITM_PID
