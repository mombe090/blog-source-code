# voir https://search.opentofu.org/provider/siderolabs/talos/latest/docs/resources/cluster_kubeconfig
resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [var.control_plane_ip] #les ips de l'ensemble des control plane du cluster
  endpoints = [var.control_plane_ip]
}

#Configuration du control plane
data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

# Application de la configuration sur le control plane
resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = var.control_plane_ip
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
      cluster = {
        proxy = {
          image = "registry.k8s.io/kube-proxy:v1.32.0"
          extraArgs = { nodeport-addresses = "0.0.0.0/0" }
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  node                 = var.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  node                 = var.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker,
    talos_machine_configuration_apply.worker_02,
  ]
  client_configuration = data.talos_client_configuration.this.client_configuration
  control_plane_nodes  = [var.control_plane_ip]
  worker_nodes         = [var.worker_01_ip, var.worker_02_ip]
  endpoints            = data.talos_client_configuration.this.endpoints
  timeouts = {
    read = "8m"
  }
}

