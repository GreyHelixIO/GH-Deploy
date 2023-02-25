locals {
    current_image_tag = jsondecode(var.current_image_tag)["imageTags"][0]
}