output "vault_token" {
  value       = vault_token.example.client_token
  description = "The generated Vault token to use in kubernetes with external secrets"
  sensitive   = true
}
