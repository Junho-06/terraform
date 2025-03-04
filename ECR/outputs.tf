output "ecr" {
  value = {
    Repository_URLs = [for repo in aws_ecr_repository.repository : repo.repository_url]
  }
}
