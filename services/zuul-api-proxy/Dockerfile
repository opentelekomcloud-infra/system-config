FROM mitmproxy/mitmproxy:10.4.2

# Copy the routing script
COPY router.py /app/router.py

# Set up working directory
WORKDIR /app

# Expose proxy port
EXPOSE 8080

# Copy CA cert to shared volume and run proxy
CMD sh -c "cp /root/.mitmproxy/mitmproxy-ca-cert.pem /mitmproxy-ca/ 2>/dev/null || true; mitmdump --mode regular@8080 --ssl-insecure -s /app/router.py --set upstream_cert=false"
