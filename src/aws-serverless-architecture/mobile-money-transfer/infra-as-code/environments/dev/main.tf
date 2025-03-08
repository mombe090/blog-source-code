terraform {
  # Utilisation du provider AWS avec la version 5.86.0
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.0"
    }
  }

  # On utilise le backend S3 pour stocker l'état de notre infrastructure avec le bucket S3 aws-serverless-fintech-solution-statefile-bucket-xsxd3 crée précédemment.
  backend "s3" {
    bucket = "aws-serverless-fintech-solution-statefile-bucket-xsxd3" # remplace par votre bucket
    key    = "serverless-app-statefile/default/terraform.tfstate"
    region = "ca-central-1"

    #Vous devez avec terraform 1.10.0 et hashicorp/aws 5.86.0 ou plus pour utiliser le verrouillage
    # Lire la documentation pour plus d'informations : https://developer.hashicorp.com/terraform/language/upgrade-guides#s3-native-state-locking
    use_lockfile = true
  }
}

module "this" {
  source = "../../modules/common"

  aws_account_id = var.aws_account_id #remplacez par votre numéro de compte AWS
  aws_region     = var.aws_region     #remplacez par la region AWS de votre choix

  issuer_uri = var.issuer_uri
  jwks_uri   = var.jwks_uri

  sms_provider_api_url       = "https://api.nimbasms.com/v1/messages"
  sms_provider_client_id     = var.sms_provider_client_id
  sms_provider_client_secret = var.sms_provider_client_secret

  //remplacez par 'ON' pour activer les notifications SMS
  enable_sms_notifications   = "OFF"

  //remplacez par 'OFF' pour ne pas activer les notifications EMAIL
  enable_email_notifications = "ON"

  //remplacez par votre domaine si apply_custom_domain est true
  domain                     = var.domain
  apply_custom_domain        = true //remplacez par false si vous ne souhaitez pas appliquer de domaine personnalisé

  test_destination_email     = var.test_email
}
