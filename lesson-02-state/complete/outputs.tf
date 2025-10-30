output "network_self_link" {
  description = "Self-link of the main network"
  value       = google_compute_network.main.self_link
}

output "subnet_details" {
  description = "Details of all subnets"
  value = {
    for key, subnet in google_compute_subnetwork.regional :
    key => {
      name      = subnet.name
      region    = subnet.region
      cidr      = subnet.ip_cidr_range
      self_link = subnet.self_link
    }
  }
}

output "vm_details" {
  description = "Details of all VMs"
  value = {
    for key, vm in google_compute_instance.regional :
    key => {
      name        = vm.name
      zone        = vm.zone
      internal_ip = vm.network_interface[0].network_ip
      external_ip = vm.network_interface[0].access_config[0].nat_ip
      self_link   = vm.self_link
    }
  }
}

output "ssh_commands" {
  description = "SSH commands for each VM"
  value = {
    for key, vm in google_compute_instance.regional :
    key => "gcloud compute ssh ${vm.name} --zone=${vm.zone}"
  }
}

output "http_urls" {
  description = "HTTP URLs for each VM"
  value = {
    for key, vm in google_compute_instance.regional :
    key => "http://${vm.network_interface[0].access_config[0].nat_ip}"
  }
}
