data "aws_secretsmanager_secret" "gh_global_terraform_credentials" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-global-terraform-SgEFp1"
}

data "aws_secretsmanager_secret" "gh_global_github_token" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-global-github-token-vGbxWq"
}

data "aws_secretsmanager_secret" "prod_build_secrets" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-api-config-prod-wvQqls"
}
data "aws_secretsmanager_secret_version" "prod_build_secret_version" {
    secret_id = data.aws_secretsmanager_secret.prod_build_secrets.id
}

data "aws_secretsmanager_secret" "qa_build_secret" {
    arn = "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-api-config-qa-E73Reo"
}
data "aws_secretsmanager_secret_version" "qa_build_secret_version" {
    secret_id = data.aws_secretsmanager_secret.qa_build_secret.id
}