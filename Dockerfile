FROM node:20-bookworm-slim

USER root

# Install dependencies
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

# Install additional dependencies for building runners
RUN apt-get update && apt-get install -y \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install uv for Python runner dependencies (version from official runners build)
ENV UV_VERSION=0.4.14
RUN wget -q "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz" -O /tmp/uv.tar.gz \
    && tar -xzf /tmp/uv.tar.gz -C /tmp \
    && mv /tmp/uv-x86_64-unknown-linux-musl/uv /usr/local/bin/uv \
    && chmod +x /usr/local/bin/uv \
    && rm -rf /tmp/uv*

# Build and install JavaScript task runner
RUN git clone https://github.com/n8n-io/task-runner-javascript.git /tmp/js-runner \
    && cd /tmp/js-runner \
    && corepack enable pnpm \
    && node -e "const fs = require('fs'); const pkg = require('./package.json'); Object.keys(pkg.dependencies || {}).forEach(k => { if (pkg.dependencies[k].startsWith('catalog:') || pkg.dependencies[k].startsWith('workspace:')) delete pkg.dependencies[k]; }); fs.writeFileSync('./package.json', JSON.stringify(pkg, null, 2));" \
    && pnpm install \
    && pnpm build \
    && pnpm add moment@2.30.1 --prod --no-lockfile \
    && mkdir -p /opt/runners/task-runner-javascript \
    && cp -r . /opt/runners/task-runner-javascript \
    && rm -rf /tmp/js-runner

# Build and install Python task runner
RUN git clone https://github.com/n8n-io/task-runner-python.git /tmp/py-runner \
    && cd /tmp/py-runner \
    && uv venv \
    && uv sync --frozen --no-editable --no-install-project --no-dev --all-extras \
    && uv sync --frozen --no-dev --all-extras --no-editable \
    && mkdir -p /opt/runners/task-runner-python \
    && cp -r . /opt/runners/task-runner-python \
    && rm -rf /tmp/py-runner

# Create workdir for runners (matches official config; chown to node since that's your user)
RUN mkdir -p /home/runner && chown -R node:node /home/runner


# Install n8n task runner launcher
RUN curl -fL -o /tmp/task-runner-launcher.tar.gz \
    https://github.com/n8n-io/task-runner-launcher/releases/download/1.4.2/task-runner-launcher-1.4.2-linux-amd64.tar.gz \
    && tar -xzf /tmp/task-runner-launcher.tar.gz -C /usr/local/bin \
    && chmod +x /usr/local/bin/task-runner-launcher \
    && rm /tmp/task-runner-launcher.tar.gz

WORKDIR /home/node

RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Add task runners config
COPY n8n-task-runners.json /etc/secrets/n8n-task-runners.json


# Supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Default env
ENV NODE_ENV=production
ENV N8N_RUNNERS_AUTH_TOKEN=a9x4HbP1YzW8c3T2sNQdF0RZ6BeYJX
ENV N8N_RUNNERS_CONFIG_PATH=/etc/secrets/n8n-task-runners.json

EXPOSE 5678
EXPOSE 5679

ENTRYPOINT ["tini", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
