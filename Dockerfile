FROM node:20-bookworm-slim

USER root

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g n8n@latest

WORKDIR /home/node

# Copy start script
COPY start.sh /home/node/start.sh
RUN chmod +x /home/node/start.sh

# Copy Python runner
COPY n8n-python-javascript /home/node/n8n-python-javascript
RUN chmod +x /home/node/n8n-python-javascript/run-python-tasks.py

ENV NODE_ENV=production
EXPOSE 5678

USER node

ENTRYPOINT ["tini", "--"]
CMD ["/home/node/start.sh"]
