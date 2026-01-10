FROM node:20-bookworm-slim

USER root

# Install Python, Pip, Tini, and Supervisor
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tini \
    supervisor \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install n8n
RUN npm install -g n8n@latest

# Install official n8n task runner launcher
RUN curl -fL -o /tmp/task-runner-launcher.tar.gz \
    https://github.com/n8n-io/task-runner-launcher/releases/download/1.4.2/task-runner-launcher-1.4.2-linux-amd64.tar.gz \
    && tar -xzf /tmp/task-runner-launcher.tar.gz -C /usr/local/bin \
    && chmod +x /usr/local/bin/task-runner-launcher \
    && rm /tmp/task-runner-launcher.tar.gz

WORKDIR /home/node

# Ensure n8n home exists
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy the task runner config to n8n home
COPY n8n-task-runners.json /home/node/.n8n/n8n-task-runners.json
RUN chown node:node /home/node/.n8n/n8n-task-runners.json

# DEBUG: Verify file existence and permissions
RUN echo "DEBUG: Listing /home/node/.n8n" \
    && ls -la /home/node/.n8n \
    && echo "DEBUG: Showing n8n-task-runners.json contents" \
    && cat /home/node/.n8n/n8n-task-runners.json \
    && echo "DEBUG: Checking task-runner-launcher version" \
    && /usr/local/bin/task-runner-launcher --version

# Set environment variable for task runners
ENV N8N_TASK_RUNNERS_FILE=/home/node/.n8n/n8n-task-runners.json
ENV NODE_ENV=production

EXPOSE 5678
EXPOSE 5679

ENTRYPOINT ["tini", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
