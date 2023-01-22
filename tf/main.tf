# variable given on terraform apply command
variable "bucket_name" {
  type    = string
  default = ""
}

# Create a S3 bucket
resource "aws_s3_bucket" "b" {
  bucket = var.bucket_name
}

# Create a S3 bucket policy
resource "aws_s3_bucket_public_access_block" "b_pab" {
  bucket = aws_s3_bucket.b.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "cf_oai" {
  comment = "OAI for ${aws_s3_bucket.b.bucket}"
}

# Create a CloudFront Distribution origin access control
resource "aws_cloudfront_origin_access_control" "cf_oac" {
  name                              = "OAC for ${aws_s3_bucket.b.bucket}"
  description                       = ""
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create a CloudFront Distribution
resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    domain_name              = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.b.bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cf_oac.id
  }
  # By default, show index.html file
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  # If there is a 404, return index.html with a HTTP 200 Response
  custom_error_response {
    error_caching_min_ttl = 3000
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.b.bucket}"
    # Forward all query strings, cookies and headers
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  ordered_cache_behavior {
    path_pattern     = "**/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.b.bucket}"
    # Forward all query strings, cookies and headers
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  # Distributes content to US and Europe
  price_class = "PriceClass_100"
  # Restricts who is able to access this content
  restrictions {
    geo_restriction {
      # type of restriction, blacklist, whitelist or none
      restriction_type = "none"
    }
  }
  # SSL certificate for the service.
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


data "aws_iam_policy_document" "d_b_policy" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.b.arn}/*"]
    actions   = ["s3:GetObject"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.cf_distribution.arn}"]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "b_policy" {
  bucket = aws_s3_bucket.b.id
  policy = data.aws_iam_policy_document.d_b_policy.json
}

output "cf_distribution_domain_name" {
  value = "https://${aws_cloudfront_distribution.cf_distribution.domain_name}"
}
