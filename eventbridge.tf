resource "aws_cloudwatch_event_rule" "spot_interruption" {
  count = var.enable_interruption_handling ? 1 : 0

  name        = "${var.cluster_name}-karpenter-spot-interruption"
  description = "Capture EC2 Spot Instance Interruption Warnings for Karpenter in ${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "spot_interruption" {
  count = var.enable_interruption_handling ? 1 : 0

  rule      = aws_cloudwatch_event_rule.spot_interruption[0].name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}

resource "aws_cloudwatch_event_rule" "instance_rebalance" {
  count = var.enable_interruption_handling ? 1 : 0

  name        = "${var.cluster_name}-karpenter-rebalance"
  description = "Capture EC2 Instance Rebalance Recommendations for Karpenter in ${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "instance_rebalance" {
  count = var.enable_interruption_handling ? 1 : 0

  rule      = aws_cloudwatch_event_rule.instance_rebalance[0].name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change" {
  count = var.enable_interruption_handling ? 1 : 0

  name        = "${var.cluster_name}-karpenter-instance-state"
  description = "Capture EC2 Instance State Change Notifications for Karpenter in ${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "instance_state_change" {
  count = var.enable_interruption_handling ? 1 : 0

  rule      = aws_cloudwatch_event_rule.instance_state_change[0].name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}

resource "aws_cloudwatch_event_rule" "scheduled_change" {
  count = var.enable_interruption_handling ? 1 : 0

  name        = "${var.cluster_name}-karpenter-scheduled-change"
  description = "Capture AWS Health Scheduled Change events for Karpenter in ${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "scheduled_change" {
  count = var.enable_interruption_handling ? 1 : 0

  rule      = aws_cloudwatch_event_rule.scheduled_change[0].name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}
