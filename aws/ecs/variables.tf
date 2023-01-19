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