# Generated with hosts.tpl
[all]
## ALL HOSTS
localhost ansible_connection=local

[RKE2_CONTROLLERS]
%{ for idx, ip in controller_ips ~}
controller${idx + 1} ansible_host=${ip} # Controller${idx + 1}
%{ endfor ~}

[RKE2_WORKERS]
%{ for idx, ip in worker_ips ~}
worker${idx + 1} ansible_host=${ip} # Worker${idx + 1}
%{ endfor ~}

[RKE2_CLUSTER:children]
RKE2_CONTROLLERS
RKE2_WORKERS
