variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["app", "nginx", "monitoring"]
}
