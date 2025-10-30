output "instance_name" {
  description = "Name of the created instance"
  value       = google_compute_instance.pipeline_test_vm.name
}

output "instance_zone" {
  description = "Zone of the instance"
  value       = google_compute_instance.pipeline_test_vm.zone
}

output "instance_id" {
  description = "ID of the instance"
  value       = google_compute_instance.pipeline_test_vm.instance_id
}

output "instance_self_link" {
  description = "Self link of the instance"
  value       = google_compute_instance.pipeline_test_vm.self_link
}

output "machine_type" {
  description = "Machine type of the instance"
  value       = google_compute_instance.pipeline_test_vm.machine_type
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.pipeline_test_vm.network_interface[0].network_ip
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
