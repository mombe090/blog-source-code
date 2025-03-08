resource "proxmox_virtual_environment_vm" "control_plane" {
  vm_id     = 10000
  name      = "control-plane"
  node_name = "pve" # Remplacez "pve" par le nom de votre serveur Proxmox

  # le provider bgp se base sur l'agent QEMU-guest-agent également pour récupérer les infos de la vm afin de le comparer à son état.
  agent {
    enabled = true
  }

  description = "Control Plane, Talos Linux charger de la gestion du cluster kubernetes"
  tags        = ["control-plane", "kubernetes", "Talos", "DEV"] # ajuster vos tags, peuvent être utilisé pour les filtres

  on_boot         = true # démarrer la vm au démarrage du serveur proxmox
  stop_on_destroy = true

  cpu {
    cores = 4               #Talos recommande 4 coeurs pour des workloads de production, 2 étant le minimum pour le control plane mais ajuster à vos bésoins.
    type  = "x86-64-v2-AES" # type de cpu moderne supporter par la plupart des serveurs et services.
  }

  memory {
    dedicated = 4096 # Talos recommande 4 Go pour des workloads de production, 2 étant le minimum pour le control plane mais ajuster à vos bésoins.
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/${var.talos_img_name}.${var.talos_version}.img"
    interface    = "virtio0"
    file_format  = "raw"
    size         = 25 # 10 Go
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${var.control_plane_ip}/24"
        gateway = var.gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }

    # ajuster si vous un server dns, sinon il prend ceux de google 8.8.8.8 et cloudflare 1.1.1.1
    /*dns {
      domain  = "local"
      servers = ["dns1", "dns2"]
    }*/
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  depends_on = [null_resource.this]
}
