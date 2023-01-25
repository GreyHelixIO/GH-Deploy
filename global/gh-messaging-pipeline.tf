resource "aws_codepipeline" "gh_messaging_pipeline" {
    name = "gh-messaging-pipeline"
    role_arn = aws_iam_role.codepipeline_role.arn

    artifact_store {
        location = aws_s3_bucket.codepipeline_bucket.bucket
        type     = "S3"
    }

    stage {
        name = "Source"

        action {
            name             = "Source"
            category         = "Source"
            owner            = "ThirdParty"
            provider         = "GitHub"
            version          = "1"
            output_artifacts = ["code"]
            configuration = {
                OAuthToken           = module.secretsmanager.GITHUB_TOKEN
                Owner                = var.repo_owner
                Repo                 = var.msg_repo
                Branch               = var.branch
                PollForSourceChanges = var.poll_for_changes
            }
        }
    }

    stage {
        name = "Build"
            action {
                name             = "Build-QA"
                category         = "Build"
                owner            = "AWS"
                provider         = "CodeBuild"
                input_artifacts  = ["code"]
                output_artifacts = ["qa_build"]
                version          = "1"

            configuration = {
                ProjectName = aws_codebuild_project.gh_messaging_build_qa.name
            }
        }
    }

    stage {
        name = "Deploy-QA"
            action {
                name             = "Deploy-QA"
                category         = "Build"
                owner            = "AWS"
                provider         = "CodeBuild"
                input_artifacts  = ["qa_build"]
                version          = "1"

            configuration = {
                ProjectName          = aws_codebuild_project.gh_messaging_deploy_qa.name
            }
        }
    }

    stage {
        name = "Approve-QA"
        action {
            name             = "Approve-QA"
            category         = "Approval"
            owner            = "AWS"
            provider         = "Manual"
            version          = "1"
        }
    }

    # stage {
    #     name = "Prod-Build"
    #         action {
    #             name             = "Prod-Build"
    #             category         = "Build"
    #             owner            = "AWS"
    #             provider         = "CodeBuild"
    #             input_artifacts  = ["code"]
    #             output_artifacts = ["prod_build"]
    #             version          = "1"

    #         configuration = {
    #             ProjectName = aws_codebuild_project.gh_api_build_prod.name
    #         }
    #     }
    # }

    # stage {
    #     name = "Deploy-Prod"
    #         action {
    #             name             = "Deploy-Prod"
    #             category         = "Build"
    #             owner            = "AWS"
    #             provider         = "CodeBuild"
    #             input_artifacts  = ["prod_build"]
    #             version          = "1"

    #         configuration = {
    #             ProjectName          = aws_codebuild_project.gh_api_deploy_prod.name
    #         }
    #     }
    # }
}

resource "aws_codebuild_project" "gh_messaging_build_qa" {
    name          = "gh-messaging-build-qa"
    description   = "CodeBuild project for building GreyHelix Messenger in QA."
    build_timeout = "5"
    service_role  = var.aws_cicd_role_arn

    artifacts {
        type = "CODEPIPELINE"
    }

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
        type                        = "LINUX_CONTAINER"
        image_pull_credentials_type = "CODEBUILD"

        privileged_mode = true

        environment_variable {
            name = "ENV"
            type = "PLAINTEXT"
            value = "qa"
        }

        environment_variable {
            name = "ECR_URL"
            type = "PLAINTEXT"
            value = aws_ecr_repository.gh_messaging_container_repo_qa.repository_url
        }

        environment_variable {
            name = "PORT"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["PORT"]
        }

        environment_variable {
            name = "AWS_ID"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["AWS_ID"]
        }

        environment_variable {
            name = "AWS_REGION"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["AWS_REGION"]
        }

        environment_variable {
            name = "AWS_SECRET"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["AWS_SECRET"]
        }

        environment_variable {
            name = "AWS_SQS_QUEUE_URL"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["AWS_SQS_QUEUE_URL"]
        }

        environment_variable {
            name = "MAILGUN_APIKEY"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["MAILGUN_APIKEY"]
        }

        environment_variable {
            name = "MAILGUN_DOMAIN"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["MAILGUN_DOMAIN"]
        }

        environment_variable {
            name = "MAILGUN_FROM"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["MAILGUN_FROM"]
        }

        environment_variable {
            name = "MAILGUN_TEMPLATE_ADDUSER"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["MAILGUN_TEMPLATE_ADDUSER"]
        }

        environment_variable {
            name = "MAILGUN_TEMPLATE_PWRESET"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["MAILGUN_TEMPLATE_PWRESET"]
        }

        environment_variable {
            name = "MAILGUN_TEMPLATE_SENDCONF"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["MAILGUN_TEMPLATE_SENDCONF"]
        }

        environment_variable {
            name = "PAPERTRAIL_API_TOKEN"
            type = "PLAINTEXT"
            value = module.secretsmanager.MESSAGING_CONFIG_QA["PAPERTRAIL_API_TOKEN"]
        }
    }

    source {
        type      = "CODEPIPELINE"
        buildspec = "./buildspec/build.yaml"
    }

    source_version = "main"
}

resource "aws_codebuild_project" "gh_messaging_deploy_qa" {
    name          = "gh-messaging-deploy-qa"
    description   = "CodeBuild project for deploying messaging app to qa."
    build_timeout = "5"
    service_role  = var.aws_cicd_role_arn

    artifacts {
        type = "CODEPIPELINE"
    }

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
        type                        = "LINUX_CONTAINER"
        image_pull_credentials_type = "CODEBUILD"

        privileged_mode = true

        environment_variable {
            name = "ENV"
            type = "PLAINTEXT"
            value = "qa"
        }

        environment_variable {
            name = "ECR_URL"
            type = "PLAINTEXT"
            value = aws_ecr_repository.gh_messaging_container_repo_qa.repository_url
        }

        environment_variable {
            name = "SERVICE"
            type = "PLAINTEXT"
            value = "messaging"
        }
    }

    source {
        type      = "CODEPIPELINE"
        buildspec = "./buildspec/deploy.yaml"
    }

    source_version = "main"
}

# resource "aws_codebuild_project" "gh_messaging_build_prod" {
#     name          = "gh-api-build-prod"
#     description   = "CodeBuild project for building CryptoSound."
#     build_timeout = "5"
#     service_role  = var.aws_cicd_role_arn

#     artifacts {
#         type = "CODEPIPELINE"
#     }

#     environment {
#         compute_type                = "BUILD_GENERAL1_SMALL"
#         image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
#         type                        = "LINUX_CONTAINER"
#         image_pull_credentials_type = "CODEBUILD"

#         privileged_mode = true

#         environment_variable {
#             name = "ENV"
#             type = "PLAINTEXT"
#             value = "prod"
#         }

#         environment_variable {
#             name = "ECR_URL"
#             type = "PLAINTEXT"
#             value = aws_ecr_repository.gh_api_api_container_repo_prod.repository_url
#         }

#         environment_variable {
#             name = "PORT"
#             type = "PLAINTEXT"
#             value = var.gh_api_port
#         }
#     }

#     source {
#         type      = "CODEPIPELINE"
#         buildspec = "./buildspec/build.yaml"
#     }

#     source_version = "main"
# }

# resource "aws_codebuild_project" "gh_api_deploy_prod" {
#     name          = "gh-api-deploy-prod"
#     description   = "CodeBuild project for deploying CryptoSound."
#     build_timeout = "5"
#     service_role  = var.aws_cicd_role_arn

#     artifacts {
#         type = "CODEPIPELINE"
#     }

#     environment {
#         compute_type                = "BUILD_GENERAL1_SMALL"
#         image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
#         type                        = "LINUX_CONTAINER"
#         image_pull_credentials_type = "CODEBUILD"

#         privileged_mode = true

#         environment_variable {
#             name = "ENV"
#             type = "PLAINTEXT"
#             value = "prod"
#         }

#         environment_variable {
#             name = "ECR_URL"
#             type = "PLAINTEXT"
#             value = aws_ecr_repository.gh_api_api_container_repo_prod.repository_url
#         }

#         environment_variable {
#             name = "PORT"
#             type = "PLAINTEXT"
#             value = var.gh_api_port
#         }

#         environment_variable {
#             name = "AWS_ID"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["AWS_ID"]}"
#         }

#         environment_variable {
#             name = "AWS_REGION"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["AWS_REGION"]}"
#         }

#         environment_variable {
#             name = "AWS_SECRET"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["AWS_SECRET"]}"
#         }

#         environment_variable {
#             name = "AWS_SNS_TOPIC_ARN"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["AWS_SNS_TOPIC_ARN"]}"
#         }

#         environment_variable {
#             name = "COOKIEDOMAIN"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["COOKIEDOMAIN"]}"
#         }

#         environment_variable {
#             name = "DB_NAME"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["DB_NAME"]}"
#         }

#         environment_variable {
#             name = "DB_PWD"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["DB_PWD"]}"
#         }

#         environment_variable {
#             name = "DB_USER"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["DB_USER"]}"
#         }

#         environment_variable {
#             name = "DEFAULTPRICE"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["DEFAULTPRICE"]}"
#         }

#         environment_variable {
#             name = "FACEBOOK_CALLBACK_URL"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["FACEBOOK_CALLBACK_URL"]}"
#         }

#         environment_variable {
#             name = "FACEBOOK_CLIENT_ID"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["FACEBOOK_CLIENT_ID"]}"
#         }

#         environment_variable {
#             name = "FACEBOOK_CLIENT_SECRET"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["FACEBOOK_CLIENT_SECRET"]}"
#         }

#         environment_variable {
#             name = "FRONTEND_URL"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["FRONTEND_URL"]}"
#         }

#         environment_variable {
#             name = "GOOGLE_CALLBACK_URL"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["GOOGLE_CALLBACK_URL"]}"
#         }

#         environment_variable {
#             name = "GOOGLE_CLIENT_ID"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["GOOGLE_CLIENT_ID"]}"
#         }

#         environment_variable {
#             name = "GOOGLE_CLIENT_SECRET"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["GOOGLE_CLIENT_SECRET"]}"
#         }

#         environment_variable {
#             name = "KEY"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["KEY"]}"
#         }

#         environment_variable {
#             name = "MAILGUN_APIKEY"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["MAILGUN_APIKEY"]}"
#         }

#         environment_variable {
#             name = "MAILGUN_DOMAIN"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["MAILGUN_DOMAIN"]}"
#         }

#         environment_variable {
#             name = "MAILGUN_FROM"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["MAILGUN_FROM"]}"
#         }

#         environment_variable {
#             name = "MAILGUN_TEMPLATE_ADDUSER"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["MAILGUN_TEMPLATE_ADDUSER"]}"
#         }

#         environment_variable {
#             name = "MAILGUN_TEMPLATE_PWRESET"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["MAILGUN_TEMPLATE_PWRESET"]}"
#         }

#         environment_variable {
#             name = "MAILGUN_TEMPLATE_SENDCONF"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["MAILGUN_TEMPLATE_SENDCONF"]}"
#         }

#         environment_variable {
#             name = "PROJECTNAME"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["PROJECTNAME"]}"
#         }

#         environment_variable {
#             name = "S3_TEST_BUCKET"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["S3_TEST_BUCKET"]}"
#         }

#         environment_variable {
#             name = "SENTRY_DSN"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["SENTRY_DSN"]}"
#         }

#         environment_variable {
#             name = "STRIPEID"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["STRIPEID"]}"
#         }

#         environment_variable {
#             name = "STRIPE_ACCOUNT_LINK_REFRESH_URL"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["STRIPE_ACCOUNT_LINK_REFRESH_URL"]}"
#         }

#         environment_variable {
#             name = "STRIPE_ACCOUNT_LINK_SUCCESS_URL"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["STRIPE_ACCOUNT_LINK_SUCCESS_URL"]}"
#         }

#         environment_variable {
#             name = "STRIPE_ACCOUNT_WEBHOOK_SECRET_ID"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["STRIPE_ACCOUNT_WEBHOOK_SECRET_ID"]}"
#         }

#         environment_variable {
#             name = "STRIPE_CHECKOUT_SUCCESS_URL"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["STRIPE_CHECKOUT_SUCCESS_URL"]}"
#         }

#         environment_variable {
#             name = "STRIPE_PAYMENT_WEBHOOK_SECRET_ID"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["STRIPE_PAYMENT_WEBHOOK_SECRET_ID"]}"
#         }

#         environment_variable {
#             name = "TRIALPERIODDAYS"
#             type = "PLAINTEXT"
#             value = "${jsondecode(data.aws_secretsmanager_secret_version.prod_build_secret_version.secret_string)["TRIALPERIODDAYS"]}"
#         }
#     }

#     source {
#         type      = "CODEPIPELINE"
#         buildspec = "./buildspec/deploy.yaml"
#     }

#     source_version = "main"
# }

resource "aws_ecr_repository" "gh_messaging_container_repo_qa" {
    name                 = "gh-messaging-container-repo-qa"
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
        scan_on_push = true
    }
}

resource "aws_ecr_repository" "gh_messaging_container_repo_stage" {
    name                 = "gh-messaging-container-repo-stage"
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
        scan_on_push = true
    }
}

resource "aws_ecr_repository" "gh_messaging_container_repo_prod" {
    name                 = "gh-messaging-container-repo-prod"
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
        scan_on_push = true
    }
}