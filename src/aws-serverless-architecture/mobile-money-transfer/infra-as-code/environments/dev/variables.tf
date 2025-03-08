variable "aws_region" {
  type        = string
  description = "Région AWS à utiliser"
  default     = "ca-central-1"
}

variable "aws_account_id" {
  description = "Le numéro de compte AWS à utiliser"
  type        = string
}

variable "issuer_uri" {
  type        = string
  description = "L'url du serveur d'authentification (Auth0/github/entraID) par exemple"
}

variable "jwks_uri" {
  type        = string
  description = "Le lien vers le fichier jwks.json de votre serveur d'authentification"
}

variable "audience" {
  type        = string
  description = "L'audience du serveur d'authentification"
}

variable "sms_provider_client_id" {
  type        = string
  description = "Le client id de votre fournisseur de SMS"
}

variable "sms_provider_client_secret" {
  type        = string
  description = "Le client secret de votre fournisseur de SMS"
}

variable "domain" {
  type        = string
  default     = "remplacez-par-votre-domaine"
  description = "Le domaine de votre application"
}

variable "test_email" {
  # nous utilisons la version production d'SES, donc nous devons fournir une adresse email et valider l'adresse email pour pouvoir envoyer des emails
  type        = string
  description = "L'adresse email de test pour la validation d'SES"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$", var.test_email))
    error_message = "La variable test_destination_email doit être une adresse email valide."
  }
}
