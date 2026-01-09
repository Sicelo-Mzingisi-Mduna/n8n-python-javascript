FROM node:20-bookworm-slim

USER root

# Install Python, Pip, Tini, and iproute2 (for port checking)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tini \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Install n8n globally
RUN npm install -g n8n@latest

WORKDIR /home/node
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

COPY start.sh /home/node/start.sh
RUN chmod +x /home/node/start.sh

ENV NODE_ENV=production
# Render needs 5678
EXPOSE 5678
# Internal broker
EXPOSE 5679

USER node

ENTRYPOINT ["tini", "--"]
CMD ["/home/node/start.sh"]