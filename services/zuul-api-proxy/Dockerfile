FROM mitmproxy/mitmproxy:10.4.2

# Copy the routing script
COPY router.py /app/router.py

# Set up working directory
WORKDIR /app

# Expose proxy port
EXPOSE 8080

# Run mitmproxy in transparent mode with the routing addon
CMD ["mitmdump", \
     "--mode", "regular@8080", \
     "--ssl-insecure", \
     "-s", "/app/router.py", \
     "--set", "upstream_cert=false"]
