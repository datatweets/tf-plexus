#!/bin/bash
# Startup script for Plexus web servers
# This script runs when the instance boots

# Update system packages
apt-get update

# Install nginx web server
apt-get install -y nginx

# Get instance metadata
INSTANCE_NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
INSTANCE_ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d'/' -f4)
INSTANCE_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

# Create custom index page
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Plexus Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .info {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .label {
            font-weight: bold;
            color: #ffd700;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 0.9em;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Plexus Web Application</h1>
        <p>Terraform-managed infrastructure running on Google Cloud Platform</p>
        
        <div class="info">
            <p><span class="label">Instance Name:</span> $INSTANCE_NAME</p>
            <p><span class="label">Zone:</span> $INSTANCE_ZONE</p>
            <p><span class="label">Internal IP:</span> $INSTANCE_IP</p>
            <p><span class="label">Environment:</span> ${environment}</p>
            <p><span class="label">Deployed:</span> $(date)</p>
        </div>
        
        <div class="footer">
            <p>✨ Built with Terraform | Managed by DevOps Team</p>
            <p>Project: Hands-On #1 - Multi-Tier Web Application</p>
        </div>
    </div>
</body>
</html>
EOF

# Start nginx
systemctl start nginx
systemctl enable nginx

# Create health check endpoint
echo "healthy" > /var/www/html/health

# Log startup completion
echo "Plexus web server startup completed at $(date)" >> /var/log/startup.log
