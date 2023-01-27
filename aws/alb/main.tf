resource "aws_alb" "application_load_balancer" {
    name               = "gh-alb-${var.env}"
    load_balancer_type = "application"
    subnets = [
        "${module.sg.default_subnet_a_id}",
        "${module.sg.default_subnet_b_id}"
    ]

    security_groups = ["${module.sg.load_balancer_security_group_id}"]
}

resource "aws_lb_target_group" "target_group" {
    name        = "gh-target-group-${var.env}"
    port        = 80
    protocol    = "HTTP"
    target_type = "ip"
    vpc_id      = "${module.sg.default_vpc_id}"
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

module "sg" {
    source = "../securitygroup"
}