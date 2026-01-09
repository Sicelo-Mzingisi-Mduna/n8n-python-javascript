FROM node:20-bookworm-slim

USER root

# 1. Install Python, Pip, Tini, and SUPERVISOR
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tini \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. Install n8n globally
RUN npm install -g n8n@latest

# 3. Create directory and permissions
WORKDIR /home/node
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# 4. Copy the Supervisor configuration file
# Ensure supervisord.conf is in the same folder as this Dockerfile when building
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 5. Define Environment Variables
ENV NODE_ENV=production

# 6. Expose ports (5678 for web, 5679 for the internal runner broker)
EXPOSE 5678
EXPOSE 5679

# 7. Switch to node user? 
# NOTE: Supervisor usually needs to start as root to spawn processes, 
# but we can tell it to run the specific programs as the 'node' user 
# if we configured it that way. For simplicity on Render, running supervisor 
# as root (which spawns n8n) is standard, but let's stick to safe practices.
# We will run as root but allow n8n to drop privileges if needed, 
# or simply run everything as root if permissions get tricky on Render.
# Given your previous file used "USER node", we can keep that if we ensure 
# permissions are correct. However, Supervisor is easiest as root.
# Let's use root to start supervisor, it's safer for process management.

ENTRYPOINT ["tini", "--"]

# Start Supervisor (which starts n8n and the python runner)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]