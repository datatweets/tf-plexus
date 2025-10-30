#!/bin/bash
# Startup script for conditional expression example

echo "Environment: ${environment}"
echo "Server started successfully!"

# Install nginx
apt-get update
apt-get install -y nginx

# Create simple page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Terraform Conditional Demo</title>
</head>
<body>
    <h1>Environment: ${environment}</h1>
    <p>Server provisioned with conditional expressions!</p>
</body>
</html>
EOF

systemctl start nginx
systemctl enable nginx
