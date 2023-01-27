output "alb_target_group_arn" {
    value = aws_lb_target_group.target_group.arn
}

output "load_balancer_dns_name" {
    value = aws_alb.application_load_balancer.dns_name
}