<!-- BEGIN_TF_DOCS -->
# Gatsby Frontend Deployment Module

## Overview

This Terraform module automates the deployment of a Gatsby static site to AWS, utilizing S3 for storage and CloudFront for content delivery. It's designed to simplify the process of setting up a scalable and efficient hosting infrastructure for Gatsby-based websites (SSG only).

## Features

- S3 bucket creation for storing Gatsby build files
- CloudFront distribution setup for global content delivery
- Automatic file upload to S3 with proper content types
- CloudFront Origin Access Identity (OAI) for secure S3 access
- S3 bucket for CloudFront access logging

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v0.14.7+ installed
- A built Gatsby project (static files generated)

## Usage

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
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The unique identifier for the Gatsby application. This name will be used as a <br>  prefix for all resources deployed by this module. Resource-specific suffixes <br>  will be appended to ensure uniqueness. <br><br>  Requirements:<br>  - Must be between 1 and 40 characters in length<br>  - Should be descriptive and reflect the application's purpose<br>  - Avoid special characters and spaces; use hyphens or underscores instead<br><br>  Example: "my-gatsby-blog" or "company-marketing-site" | `string` | n/a | yes |
| <a name="input_gatsby_build_path"></a> [gatsby\_build\_path](#input\_gatsby\_build\_path) | The relative path to the directory containing the built Gatsby static site files. <br>  This is typically the 'public' folder generated after running 'gatsby build'.<br><br>  Important notes:<br>  - The path must be relative to the location of the Terraform module file<br>  - It's recommended to use the 'path.module' variable for consistency<br>  - Ensure this path points to the directory containing index.html and other assets<br>  - Make sure that your gatsby project is purely SSG based<br><br>  Example: "\_path.module\_/../gatsby\_frontend/public" | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to be applied to all resources deployed by this module. <br>  Tags are key-value pairs that help organize and categorize resources.<br><br>  Best practices:<br>  - Use consistent naming conventions for keys and values<br>  - Include tags for environment, project, owner, and cost center<br>  - Avoid using sensitive information in tags<br><br>  Example: {<br>    "Environment" = "Production",<br>    "Project"     = "GatsbyBlog",<br>    "Owner"       = "DevOps",<br>    "CostCenter"  = "IT-12345"<br>  } | `map(string)` | `{}` | no |

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
<!-- END_TF_DOCS -->