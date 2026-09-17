output "s3_bucket_id" {
  description = "ID des provisionierten S3 Buckets"
  value       = aws_s3_bucket.backup_storage.id
}

output "iam_user_arn" {
  description = "ARN des IAM Users für Backups"
  value       = aws_iam_user.backup_user.arn
}

output "iam_access_key_id" {
  description = "Access Key ID (wird nach Erstellung manuell im Ansible Vault hinterlegt)"
  value       = aws_iam_access_key.backup_user_key.id
  sensitive   = true
}

output "iam_secret_access_key" {
  description = "Secret Access Key (wird nach Erstellung manuell im Ansible Vault hinterlegt)"
  value       = aws_iam_access_key.backup_user_key.secret
  sensitive   = true
}
