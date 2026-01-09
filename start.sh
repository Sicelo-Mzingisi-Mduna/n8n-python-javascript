#!/bin/bash
# ===================================================
# n8n startup script for Render
# Supports JS and Python task runners
# ===================================================

set -e  # Exit immediately if a command fails

# Ensure global npm binaries are in PATH
export PATH=$PATH:/usr/local/bin

# Optional: make sure Python scripts can run
export PYTHONUNBUFFERED=1

# --- Start main n8n server ---
echo "Starting n8n main server..."
n8n start &

# Give the main server a few seconds to initialize
sleep 5

# --- Start JavaScript task runner ---
echo "Starting JavaScript task runner..."
n8n task-runner &

# --- Start Python task runner ---
echo "Starting Python task runner..."
python3 /home/node/n8n-python-javascript/run-python-tasks.py &

# Wait for all background processes
wait
