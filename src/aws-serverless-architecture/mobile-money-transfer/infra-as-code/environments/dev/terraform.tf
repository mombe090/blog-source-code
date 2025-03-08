terraform {
  # Utilisation du provider AWS avec la version 5.86.0
  required_version = ">= 1.9.0"

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
