resource "minio_iam_user" "global_read_user" {
  name = "global-read"
}

# Create a policy allowing read-only access to all buckets and objects
resource "minio_iam_policy" "global_read_policy" {
  name = "global-read-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}

# Attach the policy to the user
resource "minio_iam_user_policy_attachment" "global_read_attachment" {
  user_name   = minio_iam_user.global_read_user.name
  policy_name = minio_iam_policy.global_read_policy.name
}

# Output the credentials
resource "minio_iam_service_account" "global_read_creds" {
  target_user = minio_iam_user.global_read_user.name
}

output "global_read_access_key" {
  value     = minio_iam_service_account.global_read_creds.access_key
  sensitive = true
}

output "global_read_secret_key" {
  value     = minio_iam_service_account.global_read_creds.secret_key
  sensitive = true
}
