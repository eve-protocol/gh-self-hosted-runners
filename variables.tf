variable "github_app_key" {
  description = "The GitHub App key"
  type        = string
  sensitive   = true
}

variable "acr_resource_id" {
  description = "The Azure Container Registry resource ID"
  type        = string
}

variable "github_app_id" {
  description = "The GitHub App ID"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "The GitHub App installation ID"
  type        = string
  sensitive   = true
}

variable "github_organizaion" {
  description = "The GitHub organization"
  type        = string
}
