#!/bin/bash
# Startup script for Plexus web servers
# This script installs and configures Nginx

# Update package list
apt-get update

# Install Nginx
apt-get install -y nginx

# Get instance metadata
INSTANCE_NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
INSTANCE_ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4)
INSTANCE_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

# Create custom HTML page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Plexus Web Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 { color: #fff; margin-top: 0; }
        .info { background: rgba(255, 255, 255, 0.2); padding: 15px; border-radius: 5px; margin: 10px 0; }
        .success { color: #4ade80; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏢 Plexus Web Application</h1>
        <p class="success">✓ Server is running successfully!</p>
        
        <div class="info">
            <h3>Server Information:</h3>
            <p><strong>Instance:</strong> ${INSTANCE_NAME}</p>
            <p><strong>Zone:</strong> ${INSTANCE_ZONE}</p>
            <p><strong>Internal IP:</strong> ${INSTANCE_IP}</p>
        </div>
        
        <div class="info">
            <h3>Load Balancer Test:</h3>
            <p>Each request may be served by a different instance.</p>
            <p>Refresh the page to see if the instance name changes!</p>
        </div>
    </div>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health <<EOF
OK
EOF

# Restart Nginx
systemctl restart nginx
