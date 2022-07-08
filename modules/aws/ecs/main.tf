resource "aws_ecs_task_definition" "gh_api_task" {
    family                   = "gh-api-task-${var.env}" # Naming our first task
    container_definitions    = <<DEFINITION
    [
        {
        "name": "gh-api-task-${var.env}",
        "image": "${var.ecr_api_repo_url}:${local.current_api_image_tag}",
        "essential": true,
        "environment": [
            {
                "name": "NODE_ENV",
                "value": "${var.env}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "gh-api-${var.env}"
            }
        },
        "portMappings": [
            {
                "containerPort": 80,
                "hostPort": 80
            },
            {
                "containerPort": 443,
                "hostPort": 443
            }
        ],
            "memory": 512,
            "cpu": 256
        }
    ]
    DEFINITION
    requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
    network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
    memory                   = 512         # Specifying the memory our container requires
    cpu                      = 256         # Specifying the CPU our container requires
    execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
    task_role_arn            = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
    name               = "ecsTaskExecutionRole_${var.env}"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
    role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "scp_cluster" {
    name = "scp-cluster-${var.env}"
}

resource "aws_ecs_service" "gh_api_service" {
    name            = "gh-api-service-${var.env}"        # Naming our first service
    cluster         = aws_ecs_cluster.scp_cluster.id           # Referencing our created Cluster
    task_definition = "${aws_ecs_task_definition.cs_api_task.arn}" # Referencing the task our service will spin up
    launch_type     = "FARGATE"
    desired_count   = 1 # Setting the number of containers we want deployed to 1
    deployment_minimum_healthy_percent = 0
    force_new_deployment = true
    network_configuration {
        subnets = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
        assign_public_ip = true
        security_groups  = ["${aws_security_group.service_security_group.id}"] # Setting the security group
    }
    load_balancer {
        target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
        container_name   = "${aws_ecs_task_definition.cs_api_task.family}"
        container_port   = 80 # Specifying the container port
    }
}

resource "aws_alb" "application_load_balancer" {
    name               = "gh-alb-${var.env}" # Naming our load balancer
    load_balancer_type = "application"
    subnets = [ # Referencing the default subnets
        "${aws_default_subnet.default_subnet_a.id}",
        "${aws_default_subnet.default_subnet_b.id}"
    ]
    # Referencing the security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
    ingress {
        from_port   = 80 # Allowing traffic in from port 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
    }
    ingress {
        from_port   = 443 # Allowing traffic in from port 80
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
    }

    egress {
        from_port   = 0 # Allowing any incoming port
        to_port     = 0 # Allowing any outgoing port
        protocol    = "-1" # Allowing any outgoing protocol
        cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
    }
}

resource "aws_security_group" "service_security_group" {
    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        # Only allowing traffic in from the load balancer security group
        security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
    }

    egress {
        from_port   = 0 # Allowing any incoming port
        to_port     = 0 # Allowing any outgoing port
        protocol    = "-1" # Allowing any outgoing protocol
        cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
    }
}
resource "aws_lb_target_group" "target_group" {
    name        = "gh-target-group-${var.env}"
    port        = 80
    protocol    = "HTTP"
    target_type = "ip"
    vpc_id      = "${aws_default_vpc.default_vpc.id}" # Referencing the default VPC
    health_check {
        matcher = "200,301,302"
        path = "/"
        interval = 60
    }
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # Referencing our load balancer
    port              = "80"
    protocol          = "HTTP"
    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our tagrte group
    }
}

resource "aws_cloudwatch_log_group" "log-group" {
    name = "gh-api-logs-${var.env}"

    tags = {
        Application = "gh-api-${var.env}"
        Environment = var.env
    }
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
    tags = {
        Name = "Default VPC"
    }
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
    availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
    availability_zone = "us-east-1b"
}
locals {
    ecs_servcie_secrets = var.env == "prod" ? "arn:aws:secretsmanager:us-east-1:482352589093:secret:prod-gh-config-9QASbT" : "arn:aws:secretsmanager:us-east-1:482352589093:secret:qa-gh-config-bNTQ2q"
    current_api_image_tag = jsondecode(var.current_api_image_tag)["imageTags"][0]
}

data "aws_secretsmanager_secret" "gh_service_secrets" {
    arn = local.ecs_servcie_secrets
}

data "aws_secretsmanager_secret_version" "current" {
    secret_id = data.aws_secretsmanager_secret.cs_service_secrets.id
}