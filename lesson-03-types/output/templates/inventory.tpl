[web]
%{~ for instance in web_servers ~}
${instance.name} ansible_host=${instance.network_interface[0].access_config[0].nat_ip}
%{~ endfor ~}

[database]
%{~ for instance in db_servers ~}
${instance.name} ansible_host=${instance.network_interface[0].access_config[0].nat_ip}
%{~ endfor ~}
