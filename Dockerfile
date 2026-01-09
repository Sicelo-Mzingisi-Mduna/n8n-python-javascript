FROM node:20-bookworm-slim

USER root

# Install Python, Pip, Tini, and Supervisor
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tini \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install n8n
RUN npm install -g n8n@latest

WORKDIR /home/node

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set permissions for the node user
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

ENV NODE_ENV=production
EXPOSE 5678
EXPOSE 5679

ENTRYPOINT ["tini", "--"]

# Run supervisor as root (it will manage the n8n processes)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]