# Common variables for all GKE modules
variable "region" {
  description = "GCE Region"
}
variable "env" {
  description = "Environment, prod, preprod, qa ..."
}
variable "system" {
  description = "The system, common for common resources/components"
}

variable "component" {
  description = "The component of the system"
}
variable "abs_path" {
  description = "The absolute path in the terragrunt directory owning this resources"
}

variable "project" {
  description = "GCE Project to use"
}

variable "append_name" {
  description = "Part of Name to append"
  default     = ""
}

provider "google" {
  project     = var.project
  region      = var.region
}

terraform {
  backend "gcs" {}
}
