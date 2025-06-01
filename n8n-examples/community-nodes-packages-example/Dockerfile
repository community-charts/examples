ARG N8N_VERSION=1.94.1
FROM n8nio/n8n:${N8N_VERSION}

USER root
RUN apk add --no-cache python3 py3-pip && \
    ln -sf python3 /usr/bin/python && \
    pip3 install --no-cache-dir --break-system-packages fire

USER node