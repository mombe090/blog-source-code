variable "apply_custom_domain" {
  type        = bool
  default     = false
  description = "Utiliser pour s'avoir si on map l'api gateway à votre domaine via la Route53"
}

variable "domain" {
  type        = string
  description = "Le domaine que vous voulez utiliser pour votre api gateway"
}

variable "aws_region" {
  type        = string
  default     = "ca-central-1"
  description = "AWS Region, changez par la région de votre choix"
}

variable "aws_account_id" {
  type        = string
  description = "Le numéro de compte AWS que vous utilisez, vous pouvez le trouver en haut à droite de la console AWS"
}

variable "issuer_uri" {
  type        = string
  description = "L'url du serveur d'authentification (Auth0/github/entraID) par exemple"
}

variable "jwks_uri" {
  type        = string
  description = "Le lien vers le fichier jwks.json de votre serveur d'authentification, qui contient les informations de vos clés publiques"
}

variable "audience" {
  type        = string
  description = "L'audience de votre serveur d'authentification, nous ferons une validation de l'audience dans les tokens JWT"
}

variable "sms_provider_client_id" {
  type        = string
  description = "Client id de votre fournisseur de SMS"
  sensitive   = true
}

variable "sms_provider_client_secret" {
  type        = string
  description = "Client secret de votre fournisseur de SMS"
  sensitive   = true
}

variable "sms_provider_api_url" {
  type        = string
  description = "L'url de l'api de votre fournisseur de SMS"
}

variable "enable_sms_notifications" {
  type        = string
  description = "Activer ou désactiver les notifications par SMS"
  default     = "OFF"

  validation {
    condition     = contains(["ON", "OFF"], var.enable_sms_notifications)
    error_message = "La variable enable_sms_notifications doit être soit \"ON\" soit \"OFF\". \""
  }
}

variable "enable_email_notifications" {
  type        = string
  description = "Activer ou désactiver les notifications par email"

  validation {
    condition     = contains(["ON", "OFF"], var.enable_email_notifications)
    error_message = "La variable enable_sms_notifications doit être soit \"ON\" soit \"OFF\". \""
  }
}

variable "test_destination_email" {
  # nous utilisons la version production d'SES, donc nous devons fournir une adresse email et valider l'adresse email pour pouvoir envoyer des emails
  type        = string
  description = "Adresse email de test pour valider l'adresse email"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$", var.test_destination_email))
    error_message = "La variable test_destination_email doit être une adresse email valide."
  }
}
