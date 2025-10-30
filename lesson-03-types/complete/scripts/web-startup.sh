#!/bin/bash
# Web server startup script

set -e

echo "=== Web Server Startup ==="
echo "Environment: ${environment}"
echo "Server Name: ${server_name}"
echo "Database Hosts: ${db_hosts}"

# Update system
apt-get update
apt-get install -y nginx curl

# Configure nginx
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    location / {
        return 200 "Web Server: ${server_name}\nEnvironment: ${environment}\n";
        add_header Content-Type text/plain;
    }
    
    location /health {
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
EOF

# Start nginx
systemctl restart nginx
systemctl enable nginx

echo "=== Web Server Ready ==="
