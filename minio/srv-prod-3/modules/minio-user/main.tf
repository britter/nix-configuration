terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.6.5"
    }
  }
}

locals {
  rw_object_actions = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
  ]

  ro_object_actions = [
    "s3:GetObject",
  ]

  object_actions = var.permission == "ro" ? local.ro_object_actions : local.rw_object_actions
}

resource "minio_iam_user" "this" {
  name = var.username
}

resource "minio_iam_policy" "this" {
  name = "${var.username}-${var.permission}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Object-level permissions (scoped to prefix)
      {
        Effect   = "Allow"
        Action   = local.object_actions
        Resource = "arn:aws:s3:::${var.bucket}/${var.prefix}/*"
      },
      # List permission (also scoped to prefix)
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.bucket}"
        Condition = {
          StringLike = {
            "s3:prefix" = "${var.prefix}/*"
          }
        }
      }
    ]
  })
}

resource "minio_iam_user_policy_attachment" "this" {
  user_name   = minio_iam_user.this.name
  policy_name = minio_iam_policy.this.name
}

resource "minio_iam_service_account" "this" {
  target_user = minio_iam_user.this.name
}

output "access_key" {
  value     = minio_iam_service_account.this.access_key
  sensitive = true
}

output "secret_key" {
  value     = minio_iam_service_account.this.secret_key
  sensitive = true
}
