<!-- BEGIN_TF_DOCS -->
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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.67 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.67 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.frontend_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.frontend_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_s3_bucket.cloudfront_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.frontend_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.cloudfront_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.cloudfront_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.frontend_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_website_configuration.frontend_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_s3_object.frontend_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The unique identifier for the Gatsby application. This name serves as a <br>  prefix for all resources deployed by this module, with resource-specific <br>  suffixes appended to ensure uniqueness.<br><br>  Requirements:<br>  - Length: 1-40 characters<br>  - Content: Descriptive, reflecting the application's purpose<br>  - Format: Use lowercase letters, numbers, hyphens, or underscores; avoid spaces and special characters<br><br>  Examples: "my-gatsby-blog", "company-marketing-site", "personal-portfolio"<br><br>  Note: Choose a name that balances brevity with clarity to aid in resource identification and management. | `string` | n/a | yes |
| <a name="input_cloudfront_aliases"></a> [cloudfront\_aliases](#input\_cloudfront\_aliases) | A list of alternate domain names (CNAMEs) for the CloudFront distribution.<br>  These allow the distribution to be accessed via custom domains.<br><br>  Key points:<br>  - Each alias must be a valid domain name (e.g., "www.example.com")<br>  - Requires a matching SSL certificate configured in cloudfront\_viewer\_certificate<br>  - DNS records (CNAME or A) must be set up to point to the CloudFront distribution<br><br>  Example: ["www.mygatsbyblog.com", "blog.mycompany.com"]<br><br>  For more details, see the AWS provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#aliases).<br><br><br>  Note: Ensure you have the necessary permissions and certificates before configuring aliases. | `list(string)` | `[]` | no |
| <a name="input_cloudfront_viewer_certificate"></a> [cloudfront\_viewer\_certificate](#input\_cloudfront\_viewer\_certificate) | Configuration options for the CloudFront distribution's viewer certificate.<br>  This determines how HTTPS connections are handled between viewers and CloudFront.<br><br>  Options include:<br>  - acm\_certificate\_arn: ARN of an ACM certificate for custom domain support<br>  - cloudfront\_default\_certificate: Use the default CloudFront certificate (*.cloudfront.net domain)<br>  - iam\_certificate\_id: ID of an IAM certificate (legacy option, ACM preferred)<br>  - minimum\_protocol\_version: Minimum TLS version supported<br>  - ssl\_support\_method: Method of SSL/TLS support (e.g., "sni-only" for SNI)<br><br>  For detailed information, refer to the AWS provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#viewer-certificate-arguments).<br><br>  Default: Uses the CloudFront default certificate for *.cloudfront.net domains.<br><br>  Note: Custom certificates require additional DNS configuration and domain ownership verification. | <pre>object({<br>    acm_certificate_arn = optional(string)<br>    cloudfront_default_certificate = optional(bool)<br>    iam_certificate_id = optional(string)<br>    minimum_protocol_version = optional(string)<br>    ssl_support_method = optional(string)<br>  })</pre> | <pre>{<br>  "cloudfront_default_certificate": true<br>}</pre> | no |
| <a name="input_gatsby_build_path"></a> [gatsby\_build\_path](#input\_gatsby\_build\_path) | The relative path to the directory containing the built Gatsby static site files, <br>  typically the 'public' folder generated after running 'gatsby build'.<br><br>  Key considerations:<br>  - Path must be relative to the Terraform module file location<br>  - Use the 'path.module' variable for consistency across environments<br>  - Ensure the path points to the directory containing index.html and other assets<br>  - Verify that your Gatsby project is purely Static Site Generation (SSG) based<br><br>  Note: Accurate specification of this path is crucial for successful deployment of your Gatsby site. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to be applied to all resources deployed by this module. <br>  Tags are key-value pairs that aid in organizing, categorizing, and managing resources.<br><br>  Best practices:<br>  - Use consistent, meaningful naming conventions for keys and values<br>  - Include tags for environment, project, owner, cost center, and other relevant metadata<br>  - Avoid using sensitive or frequently changing information in tags<br>  - Consider automated tagging strategies for consistency across your infrastructure<br><br>  Example:<br>  {<br>    "Environment" = "Production",<br>    "Project"     = "GatsbyBlog",<br>    "Owner"       = "DevOps",<br>    "CostCenter"  = "IT-12345",<br>    "CreatedBy"   = "Terraform"<br>  }<br><br>  Note: Effective tagging strategies can significantly improve resource management and cost allocation. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_distribution"></a> [cloudfront\_distribution](#output\_cloudfront\_distribution) | The CloudFront distribution serving the Gatsby frontend. |
| <a name="output_cloudfront_domain_name"></a> [cloudfront\_domain\_name](#output\_cloudfront\_domain\_name) | The domain name of the CloudFront distribution. |
| <a name="output_cloudfront_logs_bucket"></a> [cloudfront\_logs\_bucket](#output\_cloudfront\_logs\_bucket) | The S3 bucket used for storing CloudFront distribution logs. |
| <a name="output_distribution_hash"></a> [distribution\_hash](#output\_distribution\_hash) | A SHA1 hash of the frontend distribution content ETags. Use this value along with 'module.<name>.cloudfront\_distribution.id' to create targeted invalidations of the CloudFront cache when content changes. |
| <a name="output_frontend_bucket"></a> [frontend\_bucket](#output\_frontend\_bucket) | The S3 bucket containing the Gatsby frontend distribution files. |
| <a name="output_website_url"></a> [website\_url](#output\_website\_url) | The URL of the deployed Gatsby website. |

# Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2024-08-18

Init module

## [0.0.2] - 2024-08-18

The module does not do Cloudfront Cache invalidation automatically. It is the responsibility of the user of the module to do so.

## [0.0.3] - 2024-08-18

Added aws\_caller\_identity resolution

## [0.0.4] - 2024-08-18

Bug fix

## [0.0.5] - 2024-08-18

Adding support for Route53 connection to distribution

## [0.0.6] - 2024-08-18

Bug fix

## [0.0.7] - 2024-08-18

Bug fix

## [0.0.8] - 2024-08-18

Bug fix

## [0.1.0] - 2024-08-18

Stable release of the module.
<!-- END_TF_DOCS -->