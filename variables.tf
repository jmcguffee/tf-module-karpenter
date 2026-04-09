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

variable "interruption_queue_arn" {
  description = "ARN of the SQS queue for Karpenter interruption handling (managed by your existing SQS module)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
