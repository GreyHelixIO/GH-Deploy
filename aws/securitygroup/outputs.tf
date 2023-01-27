output "default_subnet_a_id" {
    value = aws_default_subnet.default_subnet_a.id
}

output "default_subnet_b_id" {
    value = aws_default_subnet.default_subnet_b.id
}

output "service_security_group_id" {
    value = aws_security_group.service_security_group.id
}

output "load_balancer_security_group_id" {
    value = aws_security_group.load_balancer_security_group.id
}

output "default_vpc_id" {
    vallue = aws_default_vpc.default_vpc.id
}