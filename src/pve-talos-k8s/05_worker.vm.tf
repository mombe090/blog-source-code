resource "proxmox_virtual_environment_vm" "worker-1" {
  name      = "worker-1"
  node_name = "pve" # Remplacez "pve" par le nom de votre serveur Proxmox

  # Activer l'agent QEMU-engine mais réquière le package qemu-guest-agent de talos
  # le provider bgp se base sur l'agent QEMU-engine également pour récupérer les infos de la vm afin de le comparer à son état.
  agent {
    enabled = true
  }

  description = "Worker 1, chargé de faire tourner les workloads kubernetes"
  tags        = ["worker", "kubernetes", "Talos", "DEV"] # ajuster vos tags, peuvent être utilisé pour les filtres

  on_boot         = true # démarrer la vm au démarrage du serveur proxmox
  stop_on_destroy = true

  cpu {
    cores = 1 #Talos recommande 2 coeurs pour des workloads de production, 1 étant le minimum pour le worker mais ajuster à vos bésoins.
    type  = "x86-64-v2-AES" # type de cpu moderne supporter par la plupart des serveurs et services.
  }

  memory {
    dedicated = 1024 # Talos recommande 2 Go pour des workloads de production, 1Go étant le minimum pour le worker mais ajuster à vos bésoins.
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/${var.talos_img_name}.${var.talos_version}.img"
    interface    = "virtio0"
    file_format  = "raw"
    size         = 10 # 10 Go minimum pour Talos
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${var.worker_01_ip}/24"
        gateway = "192.168.10.1"
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

