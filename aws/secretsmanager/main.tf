data "aws_secretsmanager_secret" "gh_global_github_token" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-global-github-token-vGbxWq"
}
data "aws_secretsmanager_secret_version" "gh_global_github_token_secret_version" {
    secret_id = data.aws_secretsmanager_secret.gh_global_github_token.id
}

data "aws_secretsmanager_secret" "prod_api_build_secrets" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-api-config-prod-wvQqls"
}
data "aws_secretsmanager_secret_version" "prod_api_build_secret_version" {
    secret_id = data.aws_secretsmanager_secret.prod_api_build_secrets.id
}

data "aws_secretsmanager_secret" "qa_api_build_secret" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-api-config-qa-E73Reo"
}
data "aws_secretsmanager_secret_version" "qa_api_build_secret_version" {
    secret_id = data.aws_secretsmanager_secret.qa_api_build_secret.id
}

data "aws_secretsmanager_secret" "qa_messaging_build_secret" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-messaging-config-qa-Ssdrmn"
}
data "aws_secretsmanager_secret_version" "qa_messaging_build_secret_version" {
    secret_id = data.aws_secretsmanager_secret.qa_messaging_build_secret.id
}

data "aws_secretsmanager_secret" "prod_messaging_build_secret" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-messaging-config-prod-rRm0di"
}
data "aws_secretsmanager_secret_version" "prod_messaging_build_secret_version" {
    secret_id = data.aws_secretsmanager_secret.prod_messaging_build_secret.id
}