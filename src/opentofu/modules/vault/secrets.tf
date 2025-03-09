resource "vault_generic_secret" "secret" {
  path = "${vault_mount.secret.path}/tuto"
  data_json = jsonencode(
    {
      "pihole_admin_password" = "passsword"
    }
  )
}
