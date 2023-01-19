output "GITHUB_TOKEN" {
    value = "${jsondecode(data.aws_secretsmanager_secret_version.gh_global_github_token_secret_version.secret_string)["GITHUB_TOKEN"]}"
}

output "MESSAGING_CONFIG_QA" {
    value = "${jsondecode(data.aws_secretsmanager_secret_version.qa_messaging_build_secret_version.secret_string)}"
}

output "API_CONFIG_QA" {
    value = "${jsondecode(data.aws_secretsmanager_secret_version.qa_api_build_secret_version.secret_string)}"
}