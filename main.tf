# Setting up S3 bucket to contain the frontend code
resource "aws_s3_bucket" "frontend_distribution" {
  bucket = "${var.app_name}-gatsby-dist"
  tags   = var.tags
}

resource "aws_s3_object" "frontend_distribution" {
  for_each = fileset(var.gatsby_build_path, "**/*")
  bucket   = aws_s3_bucket.frontend_distribution.id
  key      = each.value
  source   = "${var.gatsby_build_path}/${each.value}"
  etag     = filemd5("${var.gatsby_build_path}/${each.value}")

  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "svg"  = "image/svg+xml",
    "json" = "application/json",
    "yaml" = "application/yaml",
    "yml"  = "application/yml",
    "md"   = "text/markdown",
  }, split(".", each.value)[length(split(".", each.value)) - 1], "binary/octet-stream")
}

resource "aws_s3_bucket_website_configuration" "frontend_distribution" {
  bucket = aws_s3_bucket.frontend_distribution.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "frontend_distribution" {
  comment = "OAI for S3 bucket ${aws_s3_bucket.frontend_distribution.bucket}"
}

resource "aws_s3_bucket_policy" "frontend_distribution" {
  bucket = aws_s3_bucket.frontend_distribution.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "s3:GetObject",
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.frontend_distribution.arn}/*",
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.frontend_distribution.id}"
        }
      },
    ]
  })
}

# Setting up S3 bucket to contain the logs from cloudfront
resource "aws_s3_bucket" "cloudfront_logging" {
  bucket = "${var.app_name}-gatsby-cloudfront-logs"
  tags   = var.tags
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["s3:PutObject"]
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.cloudfront_logging.arn}/*"
        Principal = { "Service" : "cloudfront.amazonaws.com" }
        Condition = {
          StringEquals = { "aws:SourceArn" : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.frontend_distribution.id}" }
        }
      }
    ]
  })
}

# Setting up the cloudfront distribution
resource "aws_cloudfront_distribution" "frontend_distribution" {
  tags = var.tags
  
  origin {
    domain_name = aws_s3_bucket.frontend_distribution.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend_distribution.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend_distribution.cloudfront_access_identity_path
    }
  }

  aliases = var.cloudfront_aliases

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  custom_error_response {
    error_code            = 404
    response_page_path    = "/404.html"
    response_code         = 404
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 403
    response_page_path    = "/404.html"
    response_code         = 404
    error_caching_min_ttl = 300
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_distribution.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.cloudfront_viewer_certificate.acm_certificate_arn
    cloudfront_default_certificate = var.cloudfront_viewer_certificate.cloudfront_default_certificate
    iam_certificate_id             = var.cloudfront_viewer_certificate.iam_certificate_id
    minimum_protocol_version       = var.cloudfront_viewer_certificate.minimum_protocol_version
    ssl_support_method             = var.cloudfront_viewer_certificate.ssl_support_method
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logging.bucket_domain_name
  }
}