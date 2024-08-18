output "frontend_bucket" {
  description = "The S3 bucket containing the Gatsby frontend distribution files."
  value       = aws_s3_bucket.frontend_distribution
}

output "cloudfront_logs_bucket" {
  description = "The S3 bucket used for storing CloudFront distribution logs."
  value       = aws_s3_bucket.cloudfront_logging
}

output "cloudfront_distribution" {
  description = "The CloudFront distribution serving the Gatsby frontend."
  value       = aws_cloudfront_distribution.frontend_distribution
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "website_url" {
  description = "The URL of the deployed Gatsby website."
  value       = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
}

output "distribution_hash" {
  description = "A SHA1 hash of the frontend distribution content ETags. Use this value along with 'module.<name>.cloudfront_distribution.id' to create targeted invalidations of the CloudFront cache when content changes."
  value       = sha1(join(",", [for key, obj in aws_s3_object.frontend_distribution : obj.etag]))
}