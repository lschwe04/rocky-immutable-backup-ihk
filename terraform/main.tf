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

# Verhindert, dass der Bucket versehentlich öffentlich gemacht wird (IHK-Pflicht für DSGVO!)
resource "aws_s3_bucket_public_access_block" "strict_block" {
  bucket                  = aws_s3_bucket.backup_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.backup_storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
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
        Sid      = "AllowBackupWrites"
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = ["${aws_s3_bucket.backup_storage.arn}/*"]
      },
      {
        Sid      = "AllowBackupReadsWithIPRestriction"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.backup_storage.arn}/*"]
        Condition = {
          IpAddress = {
            # Verhindert Datenexfiltration: Restore ist nur aus dem eigenen Firmennetz erlaubt!
            "aws:SourceIp" = [var.corporate_ip_cidr]
          }
        }
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
