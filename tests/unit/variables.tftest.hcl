variables {
  cluster_name      = "test-cluster"
  cluster_endpoint  = "https://test.eks.amazonaws.com"
  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
}

run "valid_kms_deletion_window_minimum" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 7
  }

  assert {
    condition     = var.kms_key_deletion_window_in_days == 7
    error_message = "KMS deletion window should accept 7 days (minimum)"
  }
}

run "valid_kms_deletion_window_maximum" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 30
  }

  assert {
    condition     = var.kms_key_deletion_window_in_days == 30
    error_message = "KMS deletion window should accept 30 days (maximum)"
  }
}

run "invalid_kms_deletion_window_too_short" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 5
  }

  expect_failures = [
    var.kms_key_deletion_window_in_days,
  ]
}

run "invalid_kms_deletion_window_too_long" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 31
  }

  expect_failures = [
    var.kms_key_deletion_window_in_days,
  ]
}

run "valid_queue_retention_default" {
  command = plan

  assert {
    condition     = var.queue_message_retention_seconds == 300
    error_message = "Default queue retention should be 300 seconds"
  }
}

run "invalid_queue_retention_too_short" {
  command = plan

  variables {
    queue_message_retention_seconds = 30
  }

  expect_failures = [
    var.queue_message_retention_seconds,
  ]
}

run "invalid_queue_retention_too_long" {
  command = plan

  variables {
    queue_message_retention_seconds = 1209601
  }

  expect_failures = [
    var.queue_message_retention_seconds,
  ]
}
