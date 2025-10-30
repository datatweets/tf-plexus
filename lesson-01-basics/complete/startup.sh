#!/bin/bash
# Startup script for application servers

# Update system packages
apt-get update
apt-get upgrade -y

# Install basic utilities
apt-get install -y curl wget git

# Install nginx
apt-get install -y nginx

# Start nginx
systemctl start nginx
systemctl enable nginx

# Create a simple welcome page
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform Complete Example</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #4285f4;
        }
        .info {
            margin-top: 20px;
            padding: 15px;
            background: #e8f0fe;
            border-left: 4px solid #4285f4;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Terraform Complete Example</h1>
        <p>This server was created using Terraform!</p>
        <div class="info">
            <p><strong>Instance:</strong> $(hostname)</p>
            <p><strong>Status:</strong> Running</p>
            <p><strong>Created:</strong> $(date)</p>
        </div>
    </div>
</body>
</html>
EOF

echo "Startup script completed successfully!" > /var/log/startup-complete.log
