#!/bin/bash
# Load balancer startup script

set -e

echo "=== Load Balancer Startup ==="
echo "Backend IPs: ${join(",", backend_ips)}"

# Update system
apt-get update
apt-get install -y nginx

# Configure nginx as load balancer
cat > /etc/nginx/nginx.conf <<'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
%{ for ip in backend_ips ~}
        server ${ip}:80;
%{ endfor ~}
    }
    
    server {
        listen 80;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /health {
            return 200 "LB OK";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Start nginx
systemctl restart nginx
systemctl enable nginx

echo "=== Load Balancer Ready ==="
