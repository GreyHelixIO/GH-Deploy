terraform {
    backend "s3" {
        bucket = "gh-deploy-terraform"
        key = "	gh-deploy-terraform-statefile.tfstate"
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
    access_key = "${jsondecode(data.aws_secretsmanager_secret_version.gh_global_terraform_secret_version.secret_string)["AWS_ID"]}"
    secret_key = "${jsondecode(data.aws_secretsmanager_secret_version.gh_global_terraform_secret_version.secret_string)["AWS_SECRET"]}"
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
        location        = "https://github.com/GreyHelixIO/GHApi.git"
        git_clone_depth = 1
        buildspec = "./buildspec/build-pipeline.yaml"
        git_submodules_config {
            fetch_submodules = true
        }
    }

    source_version = "aws-migration"
}

resource "aws_codebuild_source_credential" "gh-github-credentials" {
    auth_type   = "PERSONAL_ACCESS_TOKEN"
    server_type = "GITHUB"
    token       = "${jsondecode(data.aws_secretsmanager_secret_version.gh_global_github_token_secret_version.secret_string)["GITHUB_TOKEN"]}"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
    bucket = "gh-pipeline-bucket"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
    bucket = aws_s3_bucket.codepipeline_bucket.id
    acl    = "private"
}