variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "suffix" {
  type    = string
  default = "1"
}

variable "service_accounts" {
  type = list(string)
}

# Google provider
provider "google" {
  project = var.project
  region  = var.region
}

# Google beta provider
provider "google-beta" {
  project = var.project
  region  = var.region
}

resource "google_iam_workload_identity_pool" "github_pool" {
  provider                  = google-beta
  workload_identity_pool_id = "github-pool-${var.suffix}"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider-${var.suffix}"
  display_name                       = "GitHub provider"
  attribute_mapping = {
    "google.subject"  = "assertion.sub"
    "attribute.aud"   = "assertion.aud"
    "attribute.actor" = "assertion.actor"
  }
  oidc {
    allowed_audiences = ["sigstore"]
    issuer_uri        = "https://vstoken.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "pool_impersonation" {
  provider           = google-beta
  for_each           = toset(var.service_accounts)
  service_account_id = "projects/${var.project}/serviceAccounts/${each.key}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/*"
}

output "workload_identity_pool_id" {
  value = google_iam_workload_identity_pool.github_pool.name
}
