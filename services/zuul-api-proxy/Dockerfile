FROM mitmproxy/mitmproxy:10.4.2

# Copy the routing script
COPY router.py /app/router.py
COPY entrypoint.sh /app/entrypoint.sh

# Set up working directory
WORKDIR /app

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

# Expose proxy port
EXPOSE 8080

# Run entrypoint script
CMD ["/app/entrypoint.sh"]
