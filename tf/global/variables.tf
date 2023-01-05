# variable "AWS_ID" {
#     type        = string
#     default     = 
# }
# variable "AWS_SECRET" {
#     type        = string
#     default     = "${jsondecode(data.aws_secretsmanager_secret_version.gh_global_terraform_secret_version.secret_string)["AWS_SECRET"]}"
# }
# variable "GITHUB_TOKEN" {
#     type    = string
#     default = 
# }
variable "aws_cicd_role_arn" {
    type = string
    description = "The arn connected to the aws role for the ci-cd pipeline."
    default = "arn:aws:iam::455667379642:role/gh-codebuild-access"
}
variable "gh_api_port" {
    type = number
    description = "Default port for the api to listen."
    default = 80
}
variable "repo_owner" {
    type        = string
    default     = "GreyHelixIO"
}
variable "repo" {
    type        = string
    default     = "GHApi"
}
variable "branch" {
    type        = string
    default     = "aws-migration"
}
variable "poll_for_changes" {
    type        = string
    default     = true
}