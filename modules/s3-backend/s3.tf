resource "aws_s3_bucket" "tf_state" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
    Env  = "final-project"
  }
}

# Server-side encryption configuration resource (separate since the in-block is deprecated)
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_sse" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Separate versioning resource (versioning block on aws_s3_bucket is deprecated)
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
