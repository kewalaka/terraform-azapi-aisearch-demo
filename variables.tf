variable "location" {
  description = "Azure region for the demo resources."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Short lowercase prefix used in resource names. Keep it alphanumeric for AI Search service naming."
  type        = string
  default     = "azapiaidp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,20}$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain 3-21 lowercase alphanumeric characters."
  }
}

variable "rbac_propagation_delay" {
  description = "Delay after assigning Search Service Contributor before data-plane calls. Increase if Azure RBAC is slow to propagate."
  type        = string
  default     = "90s"
}
