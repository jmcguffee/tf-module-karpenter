resource "aws_sqs_queue" "karpenter_interruption" {
  count = var.enable_interruption_handling ? 1 : 0

  name                      = "${var.cluster_name}-karpenter-interruption"
  message_retention_seconds = var.queue_message_retention_seconds
  sqs_managed_sse_enabled   = var.enable_kms ? false : var.queue_managed_sse_enabled
  kms_master_key_id         = var.enable_kms ? aws_kms_key.karpenter[0].arn : null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-karpenter-interruption"
  })
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  count = var.enable_interruption_handling ? 1 : 0

  queue_url = aws_sqs_queue.karpenter_interruption[0].url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeSendMessage"
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com",
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption[0].arn
      },
      {
        Sid    = "DenyNonSSL"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action   = "sqs:*"
        Resource = aws_sqs_queue.karpenter_interruption[0].arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}
