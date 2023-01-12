variable "env" {
    type        = string
    description = "The current environment being deployed."
}

variable "ecr_api_repo_url" {
    type        = string
    description = "The URL that points to the current ecr repo."
}

variable "current_api_image_tag" {
    type        = string
    description = "The current image tag for cs api repo"
}
