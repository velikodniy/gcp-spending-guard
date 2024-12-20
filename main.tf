data "google_project" "project" {
  project_id = var.project_id
}

# Create Pub/Sub topic for budget notifications
resource "google_pubsub_topic" "budget_alert" {
  name       = var.pubsub_topic_name
  project    = var.project_id
}

# Create the budget with alert
resource "google_billing_budget" "budget" {
  billing_account = var.billing_account_id
  display_name    = var.budget_display_name

  budget_filter {
    projects = ["projects/${data.google_project.project.number}"]
  }

  amount {
    specified_amount {
      currency_code = var.currency_code
      units         = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    pubsub_topic = google_pubsub_topic.budget_alert.id
  }
}

# Create Cloud Function to disable billing
data "archive_file" "function_source" {
  type        = "zip"
  output_path = "${path.module}/function/function-source.zip"

  source {
    content  = file("${path.module}/function/index.js")
    filename = "index.js"
  }

  source {
    content  = file("${path.module}/function/package.json")
    filename = "package.json"
  }
}

# Create Cloud Function
resource "google_cloudfunctions2_function" "budget_control" {
  name        = var.function_name
  location    = var.region
  project     = var.project_id
  description = "Function to disable billing when budget is exceeded"

  build_config {
    runtime     = "nodejs20"
    entry_point = "processBudgetAlert"
    source {
      storage_source {
        bucket = google_storage_bucket_object.function_code.bucket
        object = google_storage_bucket_object.function_code.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60

    service_account_email = google_service_account.budget_control.email

    environment_variables = {
      GOOGLE_CLOUD_PROJECT = var.project_id
    }

    ingress_settings = "ALLOW_INTERNAL_ONLY"
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.budget_alert.id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.budget_control.email
  }
}

# Create storage bucket for Cloud Function code
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-budget-control-function-source"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
}

# Upload function code to bucket
resource "google_storage_bucket_object" "function_code" {
  name       = "function-source-${data.archive_file.function_source.output_md5}.zip"
  depends_on = [google_storage_bucket.function_bucket]

  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_source.output_path
}

# Create service account for the function
resource "google_service_account" "budget_control" {
  account_id   = var.service_account_id
  display_name = "Budget Control Function Service Account"
  project      = var.project_id
}

# Grant billing admin permissions to the service account
resource "google_billing_account_iam_member" "billing_admin" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.budget_control.email}"
}

resource "google_project_iam_member" "billing_admin" {
  project    = var.project_id
  role       = "roles/billing.projectManager"
  member     = "serviceAccount:${google_service_account.budget_control.email}"
}

# Allow function calling
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = google_cloudfunctions2_function.budget_control.project
  location       = google_cloudfunctions2_function.budget_control.location
  cloud_function = google_cloudfunctions2_function.budget_control.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.budget_control.email}"
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  project    = google_cloudfunctions2_function.budget_control.project
  location   = google_cloudfunctions2_function.budget_control.location
  service    = google_cloudfunctions2_function.budget_control.name
  role       = "roles/run.invoker"
  member     = "serviceAccount:${google_service_account.budget_control.email}"
}

# Grant Pub/Sub subscriber permissions to the service account
resource "google_pubsub_topic_iam_member" "pubsub_subscriber" {
  project    = var.project_id
  topic      = google_pubsub_topic.budget_alert.name
  role       = "roles/pubsub.subscriber"
  member     = "serviceAccount:${google_service_account.budget_control.email}"
}
