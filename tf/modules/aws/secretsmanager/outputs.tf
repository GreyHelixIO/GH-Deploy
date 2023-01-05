output "GITHUB_TOKEN" {
    value = "${jsondecode(data.aws_secretsmanager_secret_version.gh_global_github_token_secret_version.secret_string)["GITHUB_TOKEN"]}"
}