output "instance_name" {
  description = "Name of the created instance"
  value       = google_compute_instance.test_vm.name
}

output "instance_zone" {
  description = "Zone of the instance"
  value       = google_compute_instance.test_vm.zone
}

output "instance_id" {
  description = "ID of the instance"
  value       = google_compute_instance.test_vm.instance_id
}

output "instance_self_link" {
  description = "Self link of the instance"
  value       = google_compute_instance.test_vm.self_link
}

output "machine_type" {
  description = "Machine type of the instance"
  value       = google_compute_instance.test_vm.machine_type
}

output "tags" {
  description = "Network tags assigned to the instance"
  value       = google_compute_instance.test_vm.tags
}
