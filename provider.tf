terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.40"
        }
    }

    required_version = ">= 1.2.0"
}

provider "aws" {
    shared_credentials_files = ["~/.aws/personal-creds"]
    profile                  = "personal"
    region                   = "us-east-1"
}