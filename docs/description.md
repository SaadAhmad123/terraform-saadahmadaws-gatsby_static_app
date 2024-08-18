# Gatsby Frontend Deployment Module

## Overview

This Terraform module automates the deployment of a Gatsby static site to AWS, utilizing S3 for storage and CloudFront for content delivery. It's designed to simplify the process of setting up a scalable and efficient hosting infrastructure for Gatsby-based websites (Static Site Generation only).

## Features

- S3 bucket creation for storing Gatsby build files
- CloudFront distribution setup for global content delivery
- Automatic file upload to S3 with proper content types
- CloudFront Origin Access Identity (OAI) for secure S3 access
- S3 bucket for CloudFront access logging
- Optional integration with Route53 for custom domain management

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v0.14.7+ installed
- A built Gatsby project (static files generated)

## Usage

### 1. Simple Deployment with CloudFront

```hcl
module "gatsby_frontend" {
  source  = "SaadAhmad123/gatsby_static_app/saadahmadaws"
  version = "<version number>"

  # Specify the name of your application
  app_name = "my-gatsby-blog"
  
  # Path to your Gatsby build output
  gatsby_build_path = "${path.module}/../gatsby_frontend/public"
  
  # Add tags for better resource management
  tags = {
    Environment = "Production"
    Project     = "GatsbyBlog"
  }
}

# Create a CloudFront cache invalidation after deployment
resource "null_resource" "gatsby_frontend_cache_invalidation" {
  # Trigger invalidation when the distribution changes
  triggers = {
    distribution_hash = module.gatsby_frontend.distribution_hash
  }

  # Use AWS CLI to create an invalidation
  provisioner "local-exec" {
    command = "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_KEY} aws cloudfront create-invalidation --distribution-id ${module.gatsby_frontend.cloudfront_distribution.id} --paths '/*'"
  }

  depends_on = [module.gatsby_frontend]
}
```

### 2. Advanced Deployment with CloudFront and Route53 Integration

```hcl
# Define a non-default AWS provider for us-east-1 region
# This is required for ACM certificate creation and validation
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Fetch the Route53 hosted zone for your domain
data "aws_route53_zone" "zone" {
  name = "<your-domain>.com."
}

# Create an ACM certificate for your domain
resource "aws_acm_certificate" "gatsby_frontend" {
  provider          = aws.us-east-1
  domain_name       = "<your-domain-name>"
  validation_method = "DNS"
  
  subject_alternative_names = []

  lifecycle {
    create_before_destroy = true
  }
}

# Deploy the Gatsby frontend
module "gatsby_frontend" {
  source  = "SaadAhmad123/gatsby_static_app/saadahmadaws"
  version = "<version number>"

  app_name         = "my-gatsby-site"
  gatsby_build_path = "${path.module}/../gatsby_frontend/public"
  
  # Specify the domain aliases for CloudFront
  cloudfront_aliases = ["<your-domain-name>"]

  # Configure CloudFront to use the ACM certificate
  cloudfront_viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate.gatsby_frontend.arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Environment = "Production"
    Project     = "GatsbySite"
  }
}

# Create DNS records for ACM certificate validation
resource "aws_route53_record" "gatsby_frontend__certificates" {
  for_each = {
    for dvo in aws_acm_certificate.gatsby_frontend.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

# Validate the ACM certificate
resource "aws_acm_certificate_validation" "gatsby_frontend" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.gatsby_frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.gatsby_frontend__certificates : record.fqdn]
}

# Create a Route53 record to point your domain to CloudFront
resource "aws_route53_record" "gatsby_frontend" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "<subdomain>.<your-domain>.com" # Use "" for root domain
  type    = "A"

  alias {
    name                   = module.gatsby_frontend.cloudfront_distribution.domain_name
    zone_id                = module.gatsby_frontend.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Create a CloudFront cache invalidation after deployment
resource "null_resource" "gatsby_frontend_cache_invalidation" {
  triggers = {
    distribution_hash = module.gatsby_frontend.distribution_hash
  }

  provisioner "local-exec" {
    command = "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_KEY} aws cloudfront create-invalidation --distribution-id ${module.gatsby_frontend.cloudfront_distribution.id} --paths '/*'"
  }

  depends_on = [module.gatsby_frontend]
}
```

## Assumptions and Requirements

1. The Gatsby project uses purely static site generation (SSG).
2. The built Gatsby files are located in the directory specified by `gatsby_build_path`.
3. The AWS provider is already configured in the root module or through environment variables.
4. The user running Terraform has sufficient AWS permissions to create and manage the required resources.
5. The Gatsby build includes a `404.html` file for handling not found errors.

## Important Notes

- This module creates public resources. Ensure that sensitive information is not exposed in your Gatsby build.
- For custom domains, additional configuration is required as shown in the advanced deployment example.
- The module performs a CloudFront cache invalidation after each deployment, which may incur additional costs.

## Customization

You can modify the `aws_cloudfront_distribution` resource within the module to add custom behaviors, change the price class, or adjust caching settings as needed for your specific use case.

## Security Considerations

- The S3 bucket is not publicly accessible. All access is controlled through CloudFront.
- Ensure that your AWS credentials are kept secure and not exposed in your Terraform code.
- Use IAM roles and least privilege principle when setting up AWS access for Terraform.

## Cost Considerations

This module uses AWS services that may incur costs. Be aware of the pricing for S3, CloudFront, and CloudFront invalidations in your AWS account. Monitor your usage and set up billing alerts if necessary.