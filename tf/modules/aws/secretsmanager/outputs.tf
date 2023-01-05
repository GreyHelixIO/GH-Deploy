output "AWS_ID" {
    value = "${data.aws_secretsmanager_secret.gh_global_terraform_credentials.secret_string.AWS_ID}"
}

output "AWS_SECRET" {
    value = "${data.aws_secretsmanager_secret.gh_global_terraform_credentials.secret_string.AWS_SECRET}"
}

output "GITHUB_TOKEN" {
    value = "${data.aws_secretsmanager_secret.gh_global_github_token.secret_string.GITHUB_TOKEN}"
}