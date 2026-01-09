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

COPY start.sh /home/node/start.sh
RUN chmod +x /home/node/start.sh

ENV NODE_ENV=production
EXPOSE 5678

USER node

ENTRYPOINT ["tini", "--"]
CMD ["/home/node/start.sh"]
