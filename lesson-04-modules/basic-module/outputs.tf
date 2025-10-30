# outputs.tf (root module)

output "server1_ip" {
  value       = module.server1.public_ip_address
  description = "Server 1 public IP"
}

output "server2_ip" {
  value       = module.server2.public_ip_address
  description = "Server 2 public IP (null - no static IP)"
}

output "server3_ip" {
  value       = module.server3.public_ip_address
  description = "Server 3 public IP"
}

output "all_server_ips" {
  value = {
    server1 = module.server1.public_ip_address
    server2 = module.server2.public_ip_address
    server3 = module.server3.public_ip_address
  }
  description = "All server IPs in a map"
}
