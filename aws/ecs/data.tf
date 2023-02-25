data "aws_iam_policy_document" "assume_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

data "aws_ecs_service" "gh_service" {
    cluster = aws_ecs_cluster.gh_cluster.id
    service = aws_ecs_service.gh_service.name
}