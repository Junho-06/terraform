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
  alias  = "primary"
  region = var.dynamodb.region.primary_region
  default_tags {
    tags = {
      "project" = "skills"
      "owner"   = "junho"
    }
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.dynamodb.region.secondary_region
  default_tags {
    tags = {
      "project" = "skills"
      "owner"   = "junho"
    }
  }
}
