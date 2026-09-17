variable "aws_region" {
  description = "AWS Region für das Backup-Deployment"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Eindeutiger Name des S3 WORM Buckets"
  type        = string
  default     = "ihk-immutable-backup-vault-prod"
}

variable "aws_region" {
  description = "AWS Region für das Backup-Deployment"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Eindeutiger Name des S3 WORM Buckets"
  type        = string
  default     = "ihk-immutable-backup-vault-prod"
}

variable "corporate_ip_cidr" {
  description = "Statische externe IP des Unternehmens für Exfiltrations-Schutz"
  type        = string
  default     = "198.51.100.0/24" 
}
