data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "karpenter" {
  count = var.enable_kms && var.enable_interruption_handling ? 1 : 0

  description             = "KMS key for Karpenter SQS queue encryption in ${var.cluster_name}"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowEventBridgeToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSNSToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ]
        Resource = "*"
      },
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-karpenter"
  })
}

resource "aws_kms_alias" "karpenter" {
  count = var.enable_kms && var.enable_interruption_handling ? 1 : 0

  name          = "alias/${var.cluster_name}-karpenter"
  target_key_id = aws_kms_key.karpenter[0].key_id
}
