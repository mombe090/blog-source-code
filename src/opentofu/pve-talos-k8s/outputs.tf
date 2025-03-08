output "talos_client_config" {
  description = "Talos client configuration containing the talosconfig"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "k8s_config" {
  description = "Kubernetes client configuration containing the kubeconfig"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "health_checks" {
  description = "Talos health checks id"
  value       = data.talos_cluster_health.this.id
}
