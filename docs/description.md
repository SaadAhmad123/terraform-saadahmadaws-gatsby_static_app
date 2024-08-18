# Gatsby Frontend Deployment Module

## Overview

This Terraform module automates the deployment of a Gatsby static site to AWS, utilizing S3 for storage and CloudFront for content delivery. It's designed to simplify the process of setting up a scalable and efficient hosting infrastructure for Gatsby-based websites (SSG only).

## Features

- S3 bucket creation for storing Gatsby build files
- CloudFront distribution setup for global content delivery
- Automatic file upload to S3 with proper content types
- CloudFront Origin Access Identity (OAI) for secure S3 access
- S3 bucket for CloudFront access logging
- Automatic CloudFront cache invalidation on content updates

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v0.14.7+ installed
- A built Gatsby project (static files generated)

## Usage

```hcl
module "gatsby_frontend" {
  source = "path/to/this/module"

  app_name         = "my-gatsby-blog"
  gatsby_build_path = "${path.module}/../gatsby_frontend/public"
  tags = {
    Environment = "Production"
    Project     = "GatsbyBlog"
  }
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