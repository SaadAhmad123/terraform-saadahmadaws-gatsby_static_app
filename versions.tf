terraform {
  required_version = ">= 0.14.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
  }

}