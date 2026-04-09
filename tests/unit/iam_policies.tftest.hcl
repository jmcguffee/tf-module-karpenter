variables {
  cluster_name      = "test-cluster"
  cluster_endpoint  = "https://test.eks.amazonaws.com"
  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
}

run "controller_role_naming_convention" {
  command = plan

  assert {
    condition     = aws_iam_role.karpenter_controller.name == "test-cluster-karpenter-controller"
    error_message = "Controller role name must follow the <cluster_name>-karpenter-controller convention"
  }

  assert {
    condition     = can(jsondecode(aws_iam_role.karpenter_controller.assume_role_policy))
    error_message = "Controller role trust policy must be valid JSON"
  }
}

run "controller_role_irsa_trust_policy" {
  command = plan

  variables {
    namespace            = "karpenter"
    service_account_name = "karpenter"
  }

  assert {
    condition = can(
      jsondecode(aws_iam_role.karpenter_controller.assume_role_policy).Statement[0].Condition.StringEquals
    )
    error_message = "Controller role trust policy must include OIDC StringEquals condition"
  }
}

run "node_role_naming_convention" {
  command = plan

  assert {
    condition     = aws_iam_role.karpenter_node.name == "test-cluster-karpenter-node"
    error_message = "Node role name must follow the <cluster_name>-karpenter-node convention"
  }

  assert {
    condition     = aws_iam_instance_profile.karpenter_node.name == "test-cluster-karpenter-node"
    error_message = "Instance profile name must follow the <cluster_name>-karpenter-node convention"
  }
}

run "node_lifecycle_policy_naming" {
  command = plan

  assert {
    condition     = aws_iam_policy.node_lifecycle.name == "test-cluster-karpenter-node-lifecycle"
    error_message = "Node lifecycle policy must follow the naming convention"
  }
}

run "resource_discovery_policy_naming" {
  command = plan

  assert {
    condition     = aws_iam_policy.resource_discovery.name == "test-cluster-karpenter-resource-discovery"
    error_message = "Resource discovery policy must follow the naming convention"
  }
}

run "passrole_policy_naming" {
  command = plan

  assert {
    condition     = aws_iam_policy.passrole.name == "test-cluster-karpenter-passrole"
    error_message = "PassRole policy must follow the naming convention"
  }
}

run "interruption_policy_created_when_enabled" {
  command = plan

  variables {
    enable_interruption_handling = true
  }

  assert {
    condition     = length(aws_iam_policy.interruption) == 1
    error_message = "Interruption policy must be created when interruption handling is enabled"
  }
}

run "interruption_policy_not_created_when_disabled" {
  command = plan

  variables {
    enable_interruption_handling = false
  }

  assert {
    condition     = length(aws_iam_policy.interruption) == 0
    error_message = "Interruption policy must not be created when interruption handling is disabled"
  }
}
