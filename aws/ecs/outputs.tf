output "ecs_ip_address" {
    value = aws_ecs_service.gh_service.network_configuration[0].network_configuration[0].aws_vpc_configuration[0].assign_public_ip
}