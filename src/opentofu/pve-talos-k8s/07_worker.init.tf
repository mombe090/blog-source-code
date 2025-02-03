
#Configuration du worker
data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${var.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

# Application de la configuration sur le worker
resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = var.worker_01_ip

  config_patches = [
    yamlencode({
      machine = {
        registries = {
          mirrors = {
            "docker.io" = {
              endpoints = ["https://mirror.gcr.io"]
            }
          }
        }
      }
    })
  ]

  depends_on = [proxmox_virtual_environment_vm.worker-1]
}

resource "talos_machine_configuration_apply" "worker_02" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = var.worker_02_ip

  config_patches = [
    yamlencode({
      machine = {
        registries = {
          mirrors = {
            "docker.io" = {
              endpoints = ["https://mirror.gcr.io"]
            }
          }
        }
      }
    })
  ]

  depends_on = [proxmox_virtual_environment_vm.worker-2]
}