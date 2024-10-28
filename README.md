# GCP Spending Limit Module

This Terraform/OpenTofu module creates a hard spending limit for Google Cloud Platform projects by automatically disabling billing when a budget threshold is reached.

## How It Works

- Creates a Pub/Sub topic for budget notifications
- Sets up a budget alert with configurable threshold
- Deploys a Cloud Function that automatically disables project billing when the budget is exceeded
- Configures necessary IAM permissions and service accounts

## Usage

```hcl
module "budget_control" {
  source = "git::https://github.com/velikodniy/gcp-spending-limit.git"

  project_id         = "your-project-id"
  billing_account_id = "your-billing-account-id"
  budget_amount      = 100  # Maximum budget in whole units
  region             = "us-central1"
}
```

## Requirements

- Terraform >= 1.0.0
- Google Cloud Provider >= 4.0.0
- Archive Provider >= 2.0.0
- Google Cloud project with the following APIs enabled:
  - Cloud Functions API
  - Cloud Build API
  - Cloud Billing API
  - Pub/Sub API

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

## Notes

1. The Cloud Function will automatically disable billing for the project when the budget threshold is reached.
2. Make sure the service account has the necessary permissions to disable billing.
3. Test the setup with a small budget first to ensure it works as expected.

## License

MIT Licensed. See LICENSE for full details.
