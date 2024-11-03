# GCP Spending Limit Module

This Terraform/OpenTofu module creates a hard spending limit for Google Cloud Platform projects by automatically disabling billing when a budget threshold is reached.

## How It Works

- Creates a Pub/Sub topic for budget notifications
- Sets up a budget alert with configurable threshold
- Deploys a Cloud Function that automatically disables project billing when the budget is exceeded
- Configures necessary IAM permissions and service accounts

## Requirements

The following APIs should be enabled to create the resources:

- `billingbudgets.googleapis.com`
- `cloudbilling.googleapis.com`
- `cloudbuild.googleapis.com`
- `cloudfunctions.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `eventarc.googleapis.com`
- `pubsub.googleapis.com`
- `run.googleapis.com`

## Usage

To test the module you can create `main.tf`:

```hcl
locals {
  project_id         = "<project-id>"
  billing_account_id = "<billing-account-id>"
  budget_amount      = 1     # Maximum budget in whole units
  currency_code      = "GBP" # Must match the billing currency code
  region             = "us-central1"
}

provider "google" {
  project               = local.project_id
  billing_project       = local.project_id
  user_project_override = true
}

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
  ])
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = false
}

module "budget_control" {
  source = "github.com/velikodniy/gcp-spending-guard"

  project_id         = local.project_id
  billing_account_id = local.billing_account_id
  budget_amount      = local.budget_amount
  currency_code      = local.currency_code
  region             = local.region

  depends_on = [google_project_service.services]
}
```

Note that the currency code should match the billing region.

To apply the changes, execute (replace `tofu` with `terraform` if you use Terraform):

```sh
tofu init -upgrade
tofu apply
```

### Test

To test the infrastructure you can publish an alert manually:

```sh
gcloud pubsub topics publish budget-alerts --message='{
    "budgetDisplayName": "Project Budget",
    "currencyCode": "GBP",
    "costIntervalStart": "2024-01-01T00:00:00Z",
    "costAmount": 10.01,
    "budgetAmount": 10.00,
    "budgetAmountType": "SPECIFIED_AMOUNT",
    "alertThresholdExceeded": 1.0
}'
```

You might need to update the topic name (it's `budget-alerts` in the example).
You don't have to change the body of the message.
The only significant part is the fact that `costAmount` > `budgetAmount`.

Once the command is executed, you'll see in the console that functions, buckets and other paid services are disabled.
You'll need to add billing account manually to re-enable them.

## Providers

| Name    | Version  |
| ------- | -------- |
| google  | >= 4.0.0 |
| archive | >= 2.0.0 |

## Inputs

| Name                | Description                      | Type   | Default          | Required |
| ------------------- | -------------------------------- | ------ | ---------------- | :------: |
| project_id          | The GCP project ID               | string | n/a              |   yes    |
| billing_account_id  | The ID of the billing account    | string | n/a              |   yes    |
| budget_amount       | The maximum budget amount        | number | n/a              |   yes    |
| region              | The region to deploy resources   | string | "us-central1"    |    no    |
| currency_code       | The currency code for the budget | string | "USD"            |    no    |
| budget_display_name | The display name for the budget  | string | "Project Budget" |    no    |
| pubsub_topic_name   | The name for the Pub/Sub topic   | string | "budget-alerts"  |    no    |
| function_name       | The name for the Cloud Function  | string | "budget-control" |    no    |

## Outputs

| Name            | Description                                           |
| --------------- | ----------------------------------------------------- |
| pubsub_topic_id | The ID of the Pub/Sub topic created for budget alerts |
| function_name   | The name of the deployed Cloud Function               |
| budget_name     | The resource name of the budget                       |

# Development

Make sure that you have installed [`pre-commit`](https://pre-commit.com) and enabled the hooks:

```sh
pre-commit install
```
