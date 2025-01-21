data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = [
      "qemu-guest-agent"
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

resource "null_resource" "this" {
  connection {
    type        = "ssh"
    host        = var.pve_ip
    user        = "root" # Remplacez par l'utilisateur approprié
    private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x script.sh",
      "./script.sh ${var.talos_img_name} ${var.talos_version} ${talos_image_factory_schematic.this.id}",
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}
