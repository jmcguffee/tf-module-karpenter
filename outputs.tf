output "controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.arn
}

output "controller_role_name" {
  description = "Name of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.name
}

output "node_role_arn" {
  description = "ARN of the Karpenter node IAM role"
  value       = aws_iam_role.karpenter_node.arn
}

output "node_role_name" {
  description = "Name of the Karpenter node IAM role"
  value       = aws_iam_role.karpenter_node.name
}

output "node_instance_profile_arn" {
  description = "ARN of the Karpenter node instance profile"
  value       = aws_iam_instance_profile.karpenter_node.arn
}

output "node_instance_profile_name" {
  description = "Name of the Karpenter node instance profile"
  value       = aws_iam_instance_profile.karpenter_node.name
}

output "queue_url" {
  description = "URL of the SQS interruption queue (null when interruption handling is disabled)"
  value       = var.enable_interruption_handling ? aws_sqs_queue.karpenter_interruption[0].url : null
}

output "queue_arn" {
  description = "ARN of the SQS interruption queue (null when interruption handling is disabled)"
  value       = var.enable_interruption_handling ? aws_sqs_queue.karpenter_interruption[0].arn : null
}

output "queue_name" {
  description = "Name of the SQS interruption queue (null when interruption handling is disabled)"
  value       = var.enable_interruption_handling ? aws_sqs_queue.karpenter_interruption[0].name : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SQS encryption (null when KMS or interruption handling is disabled)"
  value       = var.enable_kms && var.enable_interruption_handling ? aws_kms_key.karpenter[0].arn : null
}

output "kms_key_id" {
  description = "ID of the KMS key used for SQS encryption (null when KMS or interruption handling is disabled)"
  value       = var.enable_kms && var.enable_interruption_handling ? aws_kms_key.karpenter[0].key_id : null
}
