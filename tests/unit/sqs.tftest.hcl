mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-policy"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn = "arn:aws:iam::123456789012:instance-profile/mock-instance-profile"
    }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:test-cluster-karpenter"
      id  = "https://sqs.us-east-1.amazonaws.com/123456789012/test-cluster-karpenter"
    }
  }
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}

variables {
  cluster_name           = "test-cluster"
  cluster_endpoint       = "https://test.eks.amazonaws.com"
  oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url      = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
}

run "interruption_queue_naming_convention" {
  command = apply

  assert {
    condition     = aws_sqs_queue.interruption.name == "test-cluster-karpenter"
    error_message = "Interruption queue name must follow the <cluster_name>-karpenter convention"
  }
}

run "interruption_queue_message_retention" {
  command = apply

  assert {
    condition     = aws_sqs_queue.interruption.message_retention_seconds == 300
    error_message = "Interruption queue message retention must be 300 seconds"
  }
}

run "interruption_queue_policy_allows_eventbridge" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_sqs_queue_policy.interruption.policy).Statement :
      try(
        s.Principal.Service == "events.amazonaws.com" &&
        s.Action == "sqs:SendMessage" &&
        s.Effect == "Allow",
        false
      )
    ])
    error_message = "Queue policy must allow events.amazonaws.com to send messages"
  }
}

run "spot_interruption_rule_event_pattern" {
  command = apply

  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.spot_interruption.event_pattern).source[0] == "aws.ec2" &&
      jsondecode(aws_cloudwatch_event_rule.spot_interruption.event_pattern)["detail-type"][0] == "EC2 Spot Instance Interruption Warning"
    )
    error_message = "Spot interruption rule must match EC2 Spot Instance Interruption Warning events from aws.ec2"
  }
}

run "rebalance_rule_event_pattern" {
  command = apply

  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.rebalance.event_pattern).source[0] == "aws.ec2" &&
      jsondecode(aws_cloudwatch_event_rule.rebalance.event_pattern)["detail-type"][0] == "EC2 Instance Rebalance Recommendation"
    )
    error_message = "Rebalance rule must match EC2 Instance Rebalance Recommendation events from aws.ec2"
  }
}

run "instance_state_change_rule_event_pattern" {
  command = apply

  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.instance_state_change.event_pattern).source[0] == "aws.ec2" &&
      jsondecode(aws_cloudwatch_event_rule.instance_state_change.event_pattern)["detail-type"][0] == "EC2 Instance State-change Notification"
    )
    error_message = "Instance state change rule must match EC2 Instance State-change Notification events from aws.ec2"
  }
}

run "health_event_rule_event_pattern" {
  command = apply

  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.health_event.event_pattern).source[0] == "aws.health" &&
      jsondecode(aws_cloudwatch_event_rule.health_event.event_pattern)["detail-type"][0] == "AWS Health Event"
    )
    error_message = "Health event rule must match AWS Health Event events from aws.health"
  }
}

run "all_event_targets_point_to_interruption_queue" {
  command = apply

  assert {
    condition = alltrue([
      aws_cloudwatch_event_target.spot_interruption.arn == aws_sqs_queue.interruption.arn,
      aws_cloudwatch_event_target.rebalance.arn == aws_sqs_queue.interruption.arn,
      aws_cloudwatch_event_target.instance_state_change.arn == aws_sqs_queue.interruption.arn,
      aws_cloudwatch_event_target.health_event.arn == aws_sqs_queue.interruption.arn,
    ])
    error_message = "All EventBridge targets must point to the interruption queue"
  }
}
