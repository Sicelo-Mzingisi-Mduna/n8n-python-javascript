#!/bin/bash
# ===================================================
# n8n startup script for Render (External Mode)
# ===================================================

set -e

# Ensure global npm binaries are in PATH
export PATH=$PATH:/usr/local/bin

echo "--- 1. Starting n8n Main Server (The Broker) ---"
# This process will listen on port 5679 for runners because N8N_RUNNERS_MODE=external
n8n start &

# Wait for the main server to initialize the broker
# 10 seconds is safer to prevent connection refused errors on startup
echo "Waiting 10s for Broker to initialize..."
sleep 10

echo "--- 2. Starting JavaScript Task Runner ---"
# This handles standard JS nodes externally
n8n task-runner &

echo "--- 3. Starting Python Task Runner ---"
# This handles Python nodes externally
# It uses the env vars N8N_RUNNERS_BROKER_HOST/PORT to connect to the process above
n8n task-runner python &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?