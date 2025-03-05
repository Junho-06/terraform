terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.88.0"
    }
  }

  required_version = ">= 1.10.5"
}

provider "aws" {
  region = var.cluster.region
  default_tags {
    tags = {
      "project" = "skills"
      "owner"   = "junho"
    }
  }
}
