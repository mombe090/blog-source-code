variable "pve_ip" {
  type        = string
  description = "IP du serveur proxmox"
  default = "192.168.10.253"
}

variable "talos_img_name" {
  type        = string
  description = "Nom de l'image talos à telecharger sur https://factory.talos.dev"
  default = "talos-nocloud-amd64-qemu-agent"
}

variable "talos_version" {
  type        = string
  description = "Version de talos à telecharger sur https://factory.talos.dev"
  default = "v1.9.2"
}

variable gateway {
  type        = string
  description = "IP de la passerelle"
  default = "192.168.10.1"
}

variable "control_plane_ip" {
  type        = string
  description = "IP du control plane"
  default = "192.168.10.130"
}

variable "worker_01_ip" {
  type        = string
  description = "IP du worker 01"
  default = "192.168.10.131"
}

variable "worker_02_ip" {
  type        = string
  description = "IP du worker 02"
  default = "192.168.10.132"
}

variable "cluster_name" {
  type        = string
  description = "Nom du cluster"
  default = "k8s-demo-talos"
}