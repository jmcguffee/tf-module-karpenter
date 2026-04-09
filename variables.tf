variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where Karpenter is deployed"
  type        = string
  default     = "karpenter"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "enable_interruption_handling" {
  description = "Whether to enable interruption handling via SQS and EventBridge"
  type        = bool
  default     = true
}

variable "queue_managed_sse_enabled" {
  description = "Whether to enable SQS-managed server-side encryption (used only when enable_kms is false)"
  type        = bool
  default     = false
}

variable "enable_kms" {
  description = "Whether to create and use a customer-managed KMS key for SQS encryption"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window_in_days" {
  description = "Duration in days after which the KMS key is deleted after destruction"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "queue_message_retention_seconds" {
  description = "Message retention period in seconds for the SQS interruption queue"
  type        = number
  default     = 300

  validation {
    condition     = var.queue_message_retention_seconds >= 60 && var.queue_message_retention_seconds <= 1209600
    error_message = "Queue message retention must be between 60 seconds (1 minute) and 1209600 seconds (14 days)."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
