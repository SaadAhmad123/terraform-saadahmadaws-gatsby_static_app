variable "app_name" {
  description = <<EOT
  The unique identifier for the Gatsby application. This name serves as a 
  prefix for all resources deployed by this module, with resource-specific 
  suffixes appended to ensure uniqueness.

  Requirements:
  - Length: 1-40 characters
  - Content: Descriptive, reflecting the application's purpose
  - Format: Use lowercase letters, numbers, hyphens, or underscores; avoid spaces and special characters

  Examples: "my-gatsby-blog", "company-marketing-site", "personal-portfolio"

  Note: Choose a name that balances brevity with clarity to aid in resource identification and management.
  EOT 
  type        = string
  validation {
    condition     = length(var.app_name) >= 1 && length(var.app_name) <= 40
    error_message = "The app_name must be between 1 and 40 characters long."
  }
}

variable "gatsby_build_path" {
  description = <<EOT
  The relative path to the directory containing the built Gatsby static site files, 
  typically the 'public' folder generated after running 'gatsby build'.

  Key considerations:
  - Path must be relative to the Terraform module file location
  - Use the 'path.module' variable for consistency across environments
  - Ensure the path points to the directory containing index.html and other assets
  - Verify that your Gatsby project is purely Static Site Generation (SSG) based

  Note: Accurate specification of this path is crucial for successful deployment of your Gatsby site.
  EOT
  type        = string
}

variable "tags" {
  description = <<EOT
  A map of tags to be applied to all resources deployed by this module. 
  Tags are key-value pairs that aid in organizing, categorizing, and managing resources.

  Best practices:
  - Use consistent, meaningful naming conventions for keys and values
  - Include tags for environment, project, owner, cost center, and other relevant metadata
  - Avoid using sensitive or frequently changing information in tags
  - Consider automated tagging strategies for consistency across your infrastructure

  Example:
  {
    "Environment" = "Production",
    "Project"     = "GatsbyBlog",
    "Owner"       = "DevOps",
    "CostCenter"  = "IT-12345",
    "CreatedBy"   = "Terraform"
  }

  Note: Effective tagging strategies can significantly improve resource management and cost allocation.
  EOT
  type        = map(string)
  default     = {}
}

variable "cloudfront_viewer_certificate" {
  description = <<EOT
  Configuration options for the CloudFront distribution's viewer certificate.
  This determines how HTTPS connections are handled between viewers and CloudFront.

  Options include:
  - acm_certificate_arn: ARN of an ACM certificate for custom domain support
  - cloudfront_default_certificate: Use the default CloudFront certificate (*.cloudfront.net domain)
  - iam_certificate_id: ID of an IAM certificate (legacy option, ACM preferred)
  - minimum_protocol_version: Minimum TLS version supported
  - ssl_support_method: Method of SSL/TLS support (e.g., "sni-only" for SNI)

  For detailed information, refer to the AWS provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#viewer-certificate-arguments).

  Default: Uses the CloudFront default certificate for *.cloudfront.net domains.

  Note: Custom certificates require additional DNS configuration and domain ownership verification.
  EOT

  type = object({
    acm_certificate_arn = optional(string)
    cloudfront_default_certificate = optional(bool)
    iam_certificate_id = optional(string)
    minimum_protocol_version = optional(string)
    ssl_support_method = optional(string)
  })

  default = {
    cloudfront_default_certificate = true
  }
}

variable "cloudfront_aliases" {
  description = <<EOT
  A list of alternate domain names (CNAMEs) for the CloudFront distribution.
  These allow the distribution to be accessed via custom domains.

  Key points:
  - Each alias must be a valid domain name (e.g., "www.example.com")
  - Requires a matching SSL certificate configured in cloudfront_viewer_certificate
  - DNS records (CNAME or A) must be set up to point to the CloudFront distribution

  Example: ["www.mygatsbyblog.com", "blog.mycompany.com"]

  For more details, see the AWS provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#aliases).
  

  Note: Ensure you have the necessary permissions and certificates before configuring aliases.
  EOT

  type    = list(string)
  default = []
}