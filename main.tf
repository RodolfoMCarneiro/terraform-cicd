provider "aws" {
  access_key = ""
  secret_key = ""
  region = "us-east-1"
}

data "aws_iam_policy_document" "codebuild_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = "codebuild.amazonaws.com"
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  
  name = "Codebuild-test-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.codebuild_role.json

}

resource "aws_iam_role_policy_attachment" "codebuild_role_managed_codecommit" {
    role = aws_iam_role.codebuild_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}

data "aws_iam_policy_document" "name" {
  statement {
    actions = [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages",
        "S3:Get*",
        "s3:List*",
        "s3:Put*",
        "codecommit:GitPull",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:ListAliases",
        "iam:GetRole",
        "events:PutRole",
        "events:Describe*",
        "events:List*",
        "events:DeleteRule",
        "events:PutTargets",
        "iam:List*",
        "iam:PassRole",
        "iam:GetRolePolicy",
        "events:TagResource",
    ]
    resources = ["*"]
  }
}

resource "aws_codecommit_repository" "test_repo" {
  repository_name = "teste-repo"
}

data "aws_iam_policy_document" "codePipeline_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = "codepipeline.amazonaws.com"
    }
  }
}

resource "aws_iam_role" "codePipeline_role" {
  
  name = "CodePipeline-test-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.codepipeline.json

}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    actions = [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetRepository",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive",
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision",
        "elasticbeanstalk:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "s3:*",
        "sns:*",
        "cloudformation:*",
        "rds:*",
        "sqs:*",
        "ecs:*",
        "lambda:InvokeFunction",
        "lambda:ListFunctions",
        "opsworks:CreateDeployment",
        "opsworks:DescribeApps",
        "opsworks:DescribeCommands",
        "opsworks:DescribeDeployments",
        "opsworks:DescribeInstances",
        "opsworks:DescribeStacks",
        "opsworks:UpdateApp",
        "opsworks:UpdateStack",
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "codebuild:BatchGetBuildBatches",
        "codebuild:StartBuildBatch",
        "devicefarm:ListProjects",
        "devicefarm:ListDevicePools",
        "devicefarm:GetRun",
        "devicefarm:GetUpload",
        "devicefarm:CreateUpload",
        "devicefarm:ScheduleRun",
        "servicecatalog:ListProvisioningArtifacts",
        "servicecatalog:CreateProvisioningArtifact",
        "servicecatalog:DescribeProvisioningArtifact",
        "servicecatalog:DeleteProvisioningArtifact",
        "servicecatalog:UpdateProduct",
        "cloudformation:ValidateTemplate",
        "ecr:DescribeImages",
        "states:DescribeExecution",
        "states:DescribeStateMachine",
        "states:StartExecution",
        "appconfig:StartDeployment",
        "appconfig:StopDeployment",
        "appconfig:GetDeployment"
    ]
    resources = ["*"]
  }
}

resource "aws_codepipeline" "pipe" {
  name = "pipe-test"
  role_arn = aws_iam_role.codePipeline_role.arn

  artifact_store {
    location = ""
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = "1"
      output_artifacts = ["SourceArtifacts"]
      namespace = "SourceVariables"

      configuration = {
        RepositoryName = aws_codecommit_repository.test_repo.name
        BranchName = "master"
        OutputArtifactFormat = "CODE_ZIP"
        PollForSourceChanges = "false"
      }
      run_order = "1"
    }


  }

  stage {
    name = "Build"

    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["SourceArtifacts"]
      output_artifacts = ["BuildArtifacts"]
      namespace = "BuildVariables"

      configuration = {
        ProjectName = ""
        PrimarySource = "Source"
      }
    }
  }
}

resource "aws_codebuild_project" "test" {
  name = "teste-build"
  service_role = aws_iam_role.codebuild_role.arn
  build_timeout = "15"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/amazonlinux2-x86_64-standar:5.0"
    type = "LINUX_CONTAINER"
    privileged_mode = "false"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}