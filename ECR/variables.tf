variable "repositories_scan_enhanced" {
  type        = bool
  description = "ECR Repo Scan Enhanced Type"
  default     = true # false -> basic scan(scan on push) / true -> enhanced scan(continuous scan)
}

variable "repositories" {
  type        = map(any)
  description = "ECR repositories Map Variables"

  default = {
    myapp = {
      encrypted = true # BP
      immutable = true # BP
    }
    test = {
      encrypted = false
      immutable = false
    }
  }
}
