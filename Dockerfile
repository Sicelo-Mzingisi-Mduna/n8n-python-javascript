# Use specific node version for stability
FROM node:20-bookworm-slim

USER root

# 1. Install Python, Pip, and Tini
# We install python3-venv because n8n uses it to create isolated environments for each execution
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tini \
    && rm -rf /var/lib/apt/lists/*

# 2. Install n8n globally
RUN npm install -g n8n@latest

# 3. Create directory for n8n data
WORKDIR /home/node
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# 4. Copy the start script
COPY start.sh /home/node/start.sh
RUN chmod +x /home/node/start.sh

# 5. Set Environment
ENV NODE_ENV=production
# Main n8n port
EXPOSE 5678 
# Task Runner Broker port
EXPOSE 5679

USER node

# 6. Start via Tini
ENTRYPOINT ["tini", "--"]
CMD ["/home/node/start.sh"]