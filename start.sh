#!/bin/sh
set -e

echo "Starting n8n..."
n8n start &

echo "Waiting for broker to be ready..."
sleep 5

echo "Starting Python task runner..."
n8n task-runner python \
  --broker-host 127.0.0.1 \
  --broker-port 5679 \
  --auth-token "$N8N_RUNNERS_AUTH_TOKEN" &

wait
