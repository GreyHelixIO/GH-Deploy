resource "aws_s3_bucket" "ui_build_bucket" {
    bucket = var.env == "prod" ? var.bucket_name : "${var.env}.${var.bucket_name}"
}

resource "aws_s3_bucket_acl" "ui_build_bucket_acl" {
    bucket = aws_s3_bucket.ui_build_bucket.id
    acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "ui_web_hosting" {
    bucket = aws_s3_bucket.ui_build_bucket.bucket

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "index.html"
    }
}

resource "aws_s3_bucket_policy" "s3_bucket_ui_policy" {
    bucket = aws_s3_bucket.ui_build_bucket.id
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid":"PublicReadGetObject",
            "Effect":"Allow",
            "Principal": "*",
            "Action":["s3:GetObject"],
            "Resource":["${aws_s3_bucket.ui_build_bucket.arn}", "${aws_s3_bucket.ui_build_bucket.arn}/*"]
    }
  ]
}
EOF
}
