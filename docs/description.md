# Gatsby Frontend Deployment Module

## Overview

This Terraform module automates the deployment of a Gatsby static site to AWS, utilizing S3 for storage and CloudFront for content delivery. It's designed to simplify the process of setting up a scalable and efficient hosting infrastructure for Gatsby-based websites (SSG only).

## Features

- S3 bucket creation for storing Gatsby build files
- CloudFront distribution setup for global content delivery
- Automatic file upload to S3 with proper content types
- CloudFront Origin Access Identity (OAI) for secure S3 access
- S3 bucket for CloudFront access logging
- Allows to integrate with Route53

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v0.14.7+ installed
- A built Gatsby project (static files generated)

## Usage

### 1. Simple deployment in CloudFront.
```hcl
module "gatsby_frontend" {
  source  = "SaadAhmad123/gatsby_static_app/saadahmadaws"
  version = <version number>

  app_name         = "my-gatsby-blog"
  gatsby_build_path = "${path.module}/../gatsby_frontend/public"
  tags = {
    Environment = "Production"
    Project     = "GatsbyBlog"
  }
}

# Create an invalidation. 
# Note: The following is just one way of doing it. Use
# your prefered method if you have any.
# Create the invalidation
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

### 1. Advanced deployment in CloudFront and integration with Route53
```hcl
# Non-default AWS provider for us-east-1 region
# Required for the certifcate and its validation
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Get the hosted zone
data "aws_route53_zone" "zone" {
  name = "<domain>.com."
}

resource "aws_acm_certificate" "gatsby_frontend" {
  provider = aws.us-east-1
  domain_name       = "<domain name>
  validation_method = "DNS"
  
  subject_alternative_names = []

  lifecycle {
    create_before_destroy = true
  }
}

module "gatsby_frontend" {
  source  = "SaadAhmad123/gatsby_static_app/saadahmadaws"
  version = <version number>

  app_name         = "my-gatsby-site"
  gatsby_build_path = "${path.module}/../gatsby_frontend/public"
  cloudfront_aliases = ["domain name"]

  cloudfront_viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate.gatsby_frontend.arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Environment = "Production"
    Project     = "GatsbySite"
  }
}

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

resource "aws_acm_certificate_validation" "gatsby_frontend" {
  provider = aws.us-east-1
  certificate_arn         = aws_acm_certificate.gatsby_frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.gatsby_frontend__certificates : record.fqdn]
}

resource "aws_route53_record" "gatsby_frontend" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "<sub-domain | Optional>.<domain name>.com" # Leave "" in case of root domain
  type    = "A"

  alias {
    name                   = module.gatsby_frontend.cloudfront_distribution.domain_name
    zone_id                = module.gatsby_frontend.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


# Create an invalidation. 
# Note: The following is just one way of doing it. Use
# your prefered method if you have any.
# Create the invalidation
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

1. The Gatsby project is purely static site generation (SSG) based.
2. The built Gatsby files are located in the directory specified by `gatsby_build_path`.
3. The AWS provider is already configured in the root module or through environment variables.
4. The user running Terraform has sufficient AWS permissions to create and manage the required resources.
5. The Gatsby build includes a `404.html` file for handling not found errors.

## Important Notes

- This module creates public resources. Ensure that sensitive information is not exposed in your Gatsby build.
- The CloudFront distribution uses the default CloudFront certificate. For custom domains, additional configuration is required.
- The module performs a CloudFront cache invalidation after each deployment, which may incur additional costs.

## Customization

You can modify the `aws_cloudfront_distribution` resource to add custom behaviors, change the price class, or adjust caching settings as needed for your specific use case.

## Security Considerations

- The S3 bucket is not publicly accessible. All access is controlled through CloudFront.
- Ensure that your AWS credentials are kept secure and not exposed in your Terraform code.

## Cost Considerations

This module uses AWS services that may incur costs. Be aware of the pricing for S3, CloudFront, and CloudFront invalidations in your AWS account.