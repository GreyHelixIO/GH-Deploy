resource "aws_sqs_queue" "gh_service_queue" {
    name                        = "gh-${var.service}-queue-${var.env}"
    fifo_queue                  = false
    policy                      = aws_sqs_queue_policy.gh_service_queue_policy.arn
}

resource "aws_sqs_queue_policy" "gh_service_queue_policy" {
    queue_url = aws_sqs_queue.gh_service_queue.url

    policy = <<POLICY
    {
    "Version": "2012-10-17",
    "Id": "sqspolicy",
    "Statement":
    [
        {
        "Sid": "First",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "sqs:*",
        "Resource": "${aws_sqs_queue.gh_service_queue.arn}"
        }
    ]
}
POLICY
}