output "talos_client_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "k8s_config" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}
