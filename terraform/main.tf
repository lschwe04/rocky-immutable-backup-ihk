terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "backup_storage" {
  bucket        = var.bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.backup_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "worm_policy" {
  bucket = aws_s3_bucket.backup_storage.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 30
    }
  }
  depends_on = [aws_s3_bucket_versioning.versioning]
}

resource "aws_iam_user" "backup_user" {
  name = "ihk-backup-puller-user"
}

resource "aws_iam_access_key" "backup_user_key" {
  user = aws_iam_user.backup_user.name
}

resource "aws_iam_user_policy" "strict_backup_policy" {
  name = "StrictLeastPrivilegeBackupPolicy"
  user = aws_iam_user.backup_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowBackupWritesAndReads"
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = ["${aws_s3_bucket.backup_storage.arn}/*"]
      },
      {
        Sid      = "AllowListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.backup_storage.arn]
      },
      {
        Sid      = "DenyDestructiveActions"
        Effect   = "Deny"
        Action   = [
          "s3:DeleteBucket",
          "s3:PutBucketObjectLockConfiguration",
          "s3:PutLifecycleConfiguration"
        ]
        Resource = [
          aws_s3_bucket.backup_storage.arn,
          "${aws_s3_bucket.backup_storage.arn}/*"
        ]
      }
    ]
  })
}
