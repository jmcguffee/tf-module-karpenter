variables {
  cluster_name      = "test-cluster"
  cluster_endpoint  = "https://test.eks.amazonaws.com"
  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
}

run "sqs_queue_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_sqs_queue.karpenter_interruption) == 1
    error_message = "SQS queue must be created when interruption handling is enabled (default)"
  }

  assert {
    condition     = aws_sqs_queue.karpenter_interruption[0].name == "test-cluster-karpenter-interruption"
    error_message = "SQS queue name must follow the <cluster_name>-karpenter-interruption convention"
  }
}

run "sqs_queue_not_created_when_disabled" {
  command = plan

  variables {
    enable_interruption_handling = false
  }

  assert {
    condition     = length(aws_sqs_queue.karpenter_interruption) == 0
    error_message = "SQS queue must not be created when interruption handling is disabled"
  }
}

run "sqs_queue_retention_respected" {
  command = plan

  variables {
    queue_message_retention_seconds = 600
  }

  assert {
    condition     = aws_sqs_queue.karpenter_interruption[0].message_retention_seconds == 600
    error_message = "SQS queue message retention must match the variable value"
  }
}

run "sqs_kms_encryption_enabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_kms_key.karpenter) == 1
    error_message = "KMS key must be created when enable_kms is true (default)"
  }

  assert {
    condition     = aws_kms_key.karpenter[0].enable_key_rotation == true
    error_message = "KMS key rotation must be enabled"
  }
}

run "sqs_kms_not_created_when_disabled" {
  command = plan

  variables {
    enable_kms = false
  }

  assert {
    condition     = length(aws_kms_key.karpenter) == 0
    error_message = "KMS key must not be created when enable_kms is false"
  }
}

run "sqs_eventbridge_rules_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_event_rule.spot_interruption) == 1
    error_message = "Spot interruption EventBridge rule must be created by default"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.instance_rebalance) == 1
    error_message = "Instance rebalance EventBridge rule must be created by default"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.instance_state_change) == 1
    error_message = "Instance state change EventBridge rule must be created by default"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.scheduled_change) == 1
    error_message = "Scheduled change EventBridge rule must be created by default"
  }
}

run "sqs_eventbridge_rules_not_created_when_disabled" {
  command = plan

  variables {
    enable_interruption_handling = false
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.spot_interruption) == 0
    error_message = "Spot interruption EventBridge rule must not be created when interruption handling is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.instance_rebalance) == 0
    error_message = "Instance rebalance EventBridge rule must not be created when interruption handling is disabled"
  }
}
