variable "env" {
    type        = string
    description = "The current environment being deployed."
}

variable "ecr_repo_url" {
    type        = string
    description = "The URL that points to the current ecr repo."
}

variable "current_image_tag" {
    type        = string
    description = "The current image tag for current repo."
}

variable "service" {
    type        = string
    description = "The current service being deployed."
}

variable "env_vars" {
    type = list(map(string))
    description = "The list of environment variables to be provided for the task definition."
}

variable "alb_target_group_arn" {
    type = string
    description = "The target group arn of the ALB that the service will connect to."
}

variable "alb_security_group" {
    type = string
    description = "The security group arn of the ALB that the service will connect to."
}