output "ecs_ip_address" {
    value = aws_ecs_service.gh_service.network_configuration[0].public_ip
}