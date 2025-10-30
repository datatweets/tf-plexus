# Compute Module - Outputs

# TODO #13: Create Instance Outputs
# Export instance IDs, names, and IP addresses using for expressions

output "instance_ids" {
  description = "List of instance IDs"
  value       = # YOUR CODE: google_compute_instance.web_servers[*].id
}

output "instance_names" {
  description = "List of instance names"
  value       = # YOUR CODE: Use splat expression [*]
}

output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = # YOUR CODE: Access network_interface[0].access_config[0].nat_ip
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = # YOUR CODE: Access network_interface[0].network_ip
}

# TODO #14: Create Load Balancer Outputs (Conditional)
# Use conditional expressions: condition ? true_val : false_val

output "load_balancer_ip" {
  description = "Load balancer public IP"
  value = var.enable_load_balancer ? (
    # YOUR CODE: Reference google_compute_global_forwarding_rule.web[0].ip_address
  ) : null
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value = var.enable_load_balancer ? (
    # YOUR CODE: Create URL string "http://${ip_address}"
  ) : null
}

# TODO #15: Create Summary Output
output "compute_summary" {
  description = "Summary of compute resources"
  value = {
    instance_count = var.instance_count
    machine_type   = var.machine_type
    instances      = # YOUR CODE: Instance names
    load_balancer  = var.enable_load_balancer
    lb_ip          = var.enable_load_balancer ? null : null # YOUR CODE
  }
}
