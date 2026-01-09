#!/bin/sh
set -e

echo "Starting n8n..."
n8n start &

# Give broker a few seconds to start
sleep 5

echo "Starting JavaScript task runner..."
n8n task-runner js \
  --broker-host 127.0.0.1 \
  --broker-port 5679 \
  --auth-token "$N8N_RUNNERS_AUTH_TOKEN" &

echo "Starting Python task runner..."
n8n task-runner python \
  --broker-host 127.0.0.1 \
  --broker-port 5679 \
  --auth-token "$N8N_RUNNERS_AUTH_TOKEN" &

wait