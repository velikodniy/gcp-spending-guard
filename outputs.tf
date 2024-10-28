output "pubsub_topic_id" {
  description = "The ID of the Pub/Sub topic created for budget alerts"
  value       = google_pubsub_topic.budget_alert.id
}

output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic"
  value       = google_pubsub_topic.budget_alert.name
}

output "function_name" {
  description = "The name of the deployed Cloud Function"
  value       = google_cloudfunctions2_function.budget_control.name
}

output "function_uri" {
  description = "URI of the deployed Cloud Function"
  value       = google_cloudfunctions2_function.budget_control.service_config[0].uri
}

output "budget_name" {
  description = "The resource name of the budget"
  value       = google_billing_budget.budget.name
}

output "service_account_email" {
  description = "The email of the service account created for the Cloud Function"
  value       = google_service_account.budget_control.email
}

output "function_bucket_name" {
  description = "The name of the bucket storing the function code"
  value       = google_storage_bucket.function_bucket.name
}

output "budget_amount" {
  description = "The configured budget amount"
  value       = var.budget_amount
  sensitive   = false
}
