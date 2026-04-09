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
}

variables {
  cluster_name           = "test-cluster"
  cluster_endpoint       = "https://test.eks.amazonaws.com"
  oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url      = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  interruption_queue_arn = "arn:aws:sqs:us-east-1:123456789012:test-cluster-karpenter-interruption"
}

run "default_namespace_is_karpenter" {
  command = plan

  assert {
    condition     = var.namespace == "karpenter"
    error_message = "Default namespace must be karpenter"
  }
}

run "default_service_account_is_karpenter" {
  command = plan

  assert {
    condition     = var.service_account_name == "karpenter"
    error_message = "Default service account name must be karpenter"
  }
}

run "default_tags_are_empty" {
  command = plan

  assert {
    condition     = length(var.tags) == 0
    error_message = "Default tags must be an empty map"
  }
}

run "custom_namespace_accepted" {
  command = plan

  variables {
    namespace = "karpenter-system"
  }

  assert {
    condition     = var.namespace == "karpenter-system"
    error_message = "Custom namespace must be accepted"
  }
}

run "custom_service_account_accepted" {
  command = plan

  variables {
    service_account_name = "karpenter-sa"
  }

  assert {
    condition     = var.service_account_name == "karpenter-sa"
    error_message = "Custom service account name must be accepted"
  }
}

run "tags_are_passed_through" {
  command = plan

  variables {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }

  assert {
    condition     = var.tags["Environment"] == "production"
    error_message = "Tags must pass through to resources"
  }
}
