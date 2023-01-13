terraform {
    backend "s3" {
        bucket = "gh-terraform"
        key = "	gh-terraform-statefile.tfstate"
        region = "us-east-1"
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.19.0"
        }
    }

    required_version = ">= 0.14.9"
}

provider "aws" {
    region  = "us-east-1"
    access_key = var.AWS_ID
    secret_key = var.AWS_SECRET
}

resource "aws_codebuild_project" "gh_pipeline_builder" {
    name          = "gh-pipeline-builder"
    description   = "CodeBuild project for building up the rest of the api CICD pipeline"
    build_timeout = "5"
    service_role  = var.aws_cicd_role_arn

    artifacts {
        type = "NO_ARTIFACTS"
    }

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
        type                        = "LINUX_CONTAINER"
        image_pull_credentials_type = "CODEBUILD"
    }

    source {
        type            = "GITHUB"
        location        = "https://github.com/GreyHelixIO/GH-Deploy.git"
        git_clone_depth = 0
        buildspec = "./buildspec/build-pipelines.yaml"
        git_submodules_config {
            fetch_submodules = true
        }
    }

    source_version = "main"
}

resource "aws_codebuild_source_credential" "gh-github-credentials" {
    auth_type   = "PERSONAL_ACCESS_TOKEN"
    server_type = "GITHUB"
    token       = module.secretsmanager.GITHUB_TOKEN
}

resource "aws_s3_bucket" "codepipeline_bucket" {
    bucket = "gh-pipeline-bucket"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
    bucket = aws_s3_bucket.codepipeline_bucket.id
    acl    = "private"
}

module "secretsmanager" {
    source = "../aws/secretsmanager"
}
resource "aws_iam_role" "codepipeline_role" {
    name = "codepipeline-assume-role"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
    name = "codepipeline_policy"
    role = aws_iam_role.codepipeline_role.id

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect":"Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketVersioning",
                "s3:PutObjectAcl",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.codepipeline_bucket.arn}",
                "${aws_s3_bucket.codepipeline_bucket.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}