# Application Tier Module
# Creates application server instances

resource "google_compute_instance" "app" {
  count = var.instance_count

  name         = "${var.project_id}-app-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
    # No external IP for app tier
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip postgresql-client
    
    # Create simple app
    mkdir -p /opt/app
    cat > /opt/app/app.py <<PYTHON
import http.server
import socketserver
import socket
from datetime import datetime

PORT = 8080
hostname = socket.gethostname()

class AppHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        html = f"""
        <!DOCTYPE html>
        <html>
        <head><title>App Server {hostname}</title></head>
        <body>
          <h1>Application Tier - Server {hostname}</h1>
          <p>Instance: ${count.index + 1} of ${var.instance_count}</p>
          <p>Environment: ${var.environment}</p>
          <p>Database: ${var.db_host}</p>
          <p>Timestamp: {datetime.now()}</p>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

with socketserver.TCPServer(("", PORT), AppHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
PYTHON
    
    # Run app as service
    cat > /etc/systemd/system/app.service <<SERVICE
[Unit]
Description=Application Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE
    
    systemctl daemon-reload
    systemctl enable app
    systemctl start app
  EOF

  tags = concat(["app-tier"], var.labels != null ? [for k, v in var.labels : "${k}-${v}"] : [])

  labels = var.labels
}
