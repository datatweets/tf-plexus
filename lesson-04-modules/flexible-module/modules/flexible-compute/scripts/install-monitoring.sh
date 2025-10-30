#!/bin/bash
# Install monitoring agent

set -e

echo "Installing Google Cloud Monitoring Agent..."

# Add agent repo
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

echo "Monitoring agent installed successfully"
