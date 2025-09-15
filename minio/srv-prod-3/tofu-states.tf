resource "minio_s3_bucket" "state_bucket" {
  bucket = "tofu-states"
}

resource "minio_s3_bucket_versioning" "state_versioning" {
  bucket = minio_s3_bucket.state_bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

output "state_bucket_domain_name" {
  value = minio_s3_bucket.state_bucket.bucket_domain_name
}
