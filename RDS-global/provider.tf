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
  region = var.region.primary_region
  default_tags {
    tags = {
      "project" = "skills"
      "owner"   = "junho"
    }
  }
}
provider "aws" {
  alias  = "secondary"
  region = var.region.secondary_region
  default_tags {
    tags = {
      "project" = "skills"
      "owner"   = "junho"
    }
  }
}
