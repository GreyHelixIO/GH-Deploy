resource "aws_alb" "application_load_balancer" {
    name               = "gh-alb-${var.env}"
    load_balancer_type = "application"
    subnets = [
        aws_default_subnet.default_subnet_a.id,
        aws_default_subnet.default_subnet_b.id
    ]

    security_groups = [aws_security_group.load_balancer_security_group.id]
}

resource "aws_lb_target_group" "target_group" {
    name        = "gh-target-group-${var.env}"
    port        = 80
    protocol    = "HTTP"
    target_type = "ip"
    vpc_id      = aws_default_vpc.default_vpc.id
    health_check {
        matcher = "200,301,302"
        path = "/health"
        interval = 60
    }
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = "${aws_alb.application_load_balancer.arn}"
    port              = "80"
    protocol          = "HTTP"
    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.target_group.arn}"
    }
}

resource "aws_security_group" "load_balancer_security_group" {
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_default_vpc" "default_vpc" {
    tags = {
        Name = "Default VPC"
    }
}

resource "aws_default_subnet" "default_subnet_a" {
    availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
    availability_zone = "us-east-1b"
}