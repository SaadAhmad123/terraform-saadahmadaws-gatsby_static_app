variable "app_name" {
  description = <<EOT
  The unique identifier for the Gatsby application. This name will be used as a 
  prefix for all resources deployed by this module. Resource-specific suffixes 
  will be appended to ensure uniqueness. 

  Requirements:
  - Must be between 1 and 40 characters in length
  - Should be descriptive and reflect the application's purpose
  - Avoid special characters and spaces; use hyphens or underscores instead

  Example: "my-gatsby-blog" or "company-marketing-site"
  EOT 
  type        = string
  validation {
    condition     = length(var.app_name) >= 1 && length(var.app_name) <= 40
    error_message = "The app_name must be between 1 and 40 characters long."
  }
}

variable "gatsby_build_path" {
  description = <<EOT
  The relative path to the directory containing the built Gatsby static site files. 
  This is typically the 'public' folder generated after running 'gatsby build'.

  Important notes:
  - The path must be relative to the location of the Terraform module file
  - It's recommended to use the 'path.module' variable for consistency
  - Ensure this path points to the directory containing index.html and other assets
  - Make sure that your gatsby project is purely SSG based

  Example: "_path.module_/../gatsby_frontend/public"
  EOT
  type        = string
}

variable "tags" {
  description = <<EOT
  A map of tags to be applied to all resources deployed by this module. 
  Tags are key-value pairs that help organize and categorize resources.

  Best practices:
  - Use consistent naming conventions for keys and values
  - Include tags for environment, project, owner, and cost center
  - Avoid using sensitive information in tags

  Example: {
    "Environment" = "Production",
    "Project"     = "GatsbyBlog",
    "Owner"       = "DevOps",
    "CostCenter"  = "IT-12345"
  }
  EOT
  type        = map(string)
  default     = {}
}