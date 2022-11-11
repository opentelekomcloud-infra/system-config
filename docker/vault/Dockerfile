from vault:1.12.1

LABEL maintainer="Ecosystem squad - DL-PBCOTCDELECO@t-systems.com"

RUN apk add --no-cache curl && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod a+x kubectl && \
    mv kubectl /usr/local/bin/
