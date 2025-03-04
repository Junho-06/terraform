variable "region" {
  default = "ap-northeast-2"
}

variable "repositories_scan_enhanced" {
  type        = bool
  description = "ECR Repo Scan Enhanced Type"
  default     = true # false -> basic scan(scan on push) / true -> enhanced scan(continuous scan)
}

variable "repositories" {
  type        = map(any)
  description = "ECR repositories Map Variables"

  default = {
    repo_name_here1 = {
      encrypted = true # BP
      immutable = true # BP
    }
    repo_name_here2 = {
      encrypted = false
      immutable = false
    }
  }
}
