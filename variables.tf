# Project

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy resources to"
  type        = string
  default     = "us-central1"
}

# Billing
variable "billing_account_id" {
  description = "The ID of the billing account to associate with the budget"
  type        = string
}

# Budget
variable "budget_display_name" {
  description = "The display name for the budget"
  type        = string
  default     = "Project Budget"
}

variable "budget_amount" {
  description = "The amount to set for the budget"
  type        = number
}

variable "currency_code" {
  description = "The currency code for the budget amount"
  type        = string
  default     = "USD"
}

# Pub/Sub
variable "pubsub_topic_name" {
  description = "The name for the Pub/Sub topic"
  type        = string
  default     = "budget-alerts"
}

# Function
variable "function_name" {
  description = "The name for the Cloud Function"
  type        = string
  default     = "budget-control"
}

# Service Acount
variable "service_account_id" {
  description = "The name of the service account managing billig"
  type        = string
  default     = "budget-control"
}
