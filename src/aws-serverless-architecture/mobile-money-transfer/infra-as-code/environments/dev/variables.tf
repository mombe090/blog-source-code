variable "aws_region" {
  type    = string
  default = "ca-central-1"
}

variable "aws_account_id" {
  type    = string
}

variable "issuer_uri" {
  type        = string
  description = "L'url du serveur d'authentification (Auth0/github/entraID) par exemple"
}

variable "jwks_uri" {
  type        = string
  description = "Le lien vers le fichier jwks.json de votre serveur d'authentification"
}


variable "sms_provider_client_id" {
  type = string
}

variable "sms_provider_client_secret" {
  type = string
}

variable "domain" {
  type    = string
  default = "remplacez-par-votre-domaine"
}

variable "test_email" {
  // nous utilisons la version production d'SES, donc nous devons fournir une adresse email et valider l'adresse email pour pouvoir envoyer des emails
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$", var.test_email))
    error_message = "La variable test_destination_email doit être une adresse email valide."
  }
}