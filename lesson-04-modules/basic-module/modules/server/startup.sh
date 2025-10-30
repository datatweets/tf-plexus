#!/bin/bash
# modules/server/startup.sh

echo "Server provisioned by Terraform module!"
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
