mock_provider "aws" {}

variables {
  cluster_name           = "test-cluster"
  cluster_endpoint       = "https://test.eks.amazonaws.com"
  oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url      = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  interruption_queue_arn = "arn:aws:sqs:us-east-1:123456789012:test-cluster-karpenter-interruption"
}

run "interruption_policy_allows_required_sqs_actions" {
  command = plan

  assert {
    condition = alltrue([
      for action in ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl", "sqs:ReceiveMessage"] :
      anytrue([
        for s in jsondecode(data.aws_iam_policy_document.interruption.json).Statement :
        contains(tolist(s.Action), action)
      ])
    ])
    error_message = "Interruption policy must allow all four required SQS actions"
  }
}

run "interruption_policy_does_not_allow_send_message" {
  command = plan

  assert {
    condition = alltrue([
      for s in jsondecode(data.aws_iam_policy_document.interruption.json).Statement :
      !contains(tolist(s.Action), "sqs:SendMessage")
    ])
    error_message = "Interruption policy must not grant sqs:SendMessage — the controller only reads from the queue"
  }
}

run "interruption_policy_naming_convention" {
  command = plan

  assert {
    condition     = aws_iam_policy.interruption.name == "test-cluster-karpenter-interruption"
    error_message = "Interruption policy name must follow the <cluster_name>-karpenter-interruption convention"
  }
}

run "interruption_queue_arn_is_used_as_resource" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(data.aws_iam_policy_document.interruption.json).Statement :
      contains(tolist(s.Resource), var.interruption_queue_arn)
    ])
    error_message = "Interruption policy resource must exactly match the provided queue ARN"
  }
}

run "different_queue_arn_is_respected" {
  command = plan

  variables {
    interruption_queue_arn = "arn:aws:sqs:eu-west-1:999999999999:prod-cluster-karpenter"
  }

  assert {
    condition = anytrue([
      for s in jsondecode(data.aws_iam_policy_document.interruption.json).Statement :
      contains(tolist(s.Resource), "arn:aws:sqs:eu-west-1:999999999999:prod-cluster-karpenter")
    ])
    error_message = "Interruption policy must use the caller-provided queue ARN, not a hardcoded value"
  }
}
