output "private_ip" {
    value = aws_ecs_service.gh_service.tasks.0.network_interface.0.private_ip_address
}