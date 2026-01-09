#!/bin/bash
set -e

# 1. Cleanup & Path Security
# Using absolute paths is the safest way to ensure the commands are found
N8N_BIN=$(which n8n || echo "/usr/local/bin/n8n")

# Kill any ghost processes if the container restarted internally
fuser -k 5678/tcp || true
fuser -k 5679/tcp || true

echo "--- 1. Starting n8n Main Server ---"
# We run the main server in the background
$N8N_BIN start &
MAIN_PID=$!

# 2. Wait for Port Binding
# This loop ensures the Broker (5679) is actually listening before the worker tries to join
echo "Waiting for n8n Broker to initialize on port 5679..."
MAX_RETRIES=20
COUNT=0
until ss -lnt | grep -q :5679; do
  if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "Error: n8n Main Server failed to start the Broker in time."
    exit 1
  fi
  sleep 2
  ((COUNT++))
done

echo "--- 2. Starting External Python Runner ---"
# We use 'worker' to handle Python tasks. 
# It will automatically use your N8N_RUNNERS_AUTH_TOKEN and 127.0.0.1:5679 env vars.
$N8N_BIN worker --task-runner:type=python &
WORKER_PID=$!

echo "n8n and Python Runner are now active."

# 3. Process Monitoring
# This 'wait -n' ensures that if EITHER the main server or the worker crashes,
# the script exits, causing Render to restart the container immediately.
wait -n

# Exit with the status of the process that died
exit $?