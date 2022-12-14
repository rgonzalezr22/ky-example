/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_iam_workload_identity_pool" "default" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = "${local.prefix}-iwip"
}

resource "google_iam_workload_identity_pool_provider" "default" {
  provider = google-beta
  for_each = local.identity_providers
  project  = var.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-iac-${each.key}"
  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping
  oidc {
    allowed_audiences = (
      try(each.value.custom_settings.allowed_audiences, null) != null
      ? each.value.custom_settings.allowed_audiences
      : try(each.value.allowed_audiences, null)
    )
    issuer_uri = (
      try(each.value.custom_settings.issuer_uri, null) != null
      ? each.value.custom_settings.issuer_uri
      : try(each.value.issuer_uri, null)
    )
  }
}

# SAs used by CI/CD workflows to impersonate automation SAs
module "iac-sa-impersonate" {
  source      = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account"
  project_id  = var.project_id
  name        = "github-impersonate"
  description = "Terraform CI/CD github service account."
  prefix      = local.prefix
  iam = (
    {
      "roles/iam.workloadIdentityUser" = [
        format(
          local.identity_providers_defs.github.principalset_tpl,
          google_iam_workload_identity_pool.default.name,
          var.cicd_repository
        )
      ]
    }
  )
  iam_project_roles = {
    (var.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.iac-outputs-gcs.name) = ["roles/storage.objectViewer"]
  }
}

module "iac-tf-sa" {
  source      = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account"
  project_id  = var.project_id
  name        = "iac-sa"
  description = "Terraform IaC service account."
  prefix      = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [module.iac-sa-impersonate.iam_email]
  }
  iam_storage_roles = {
    (module.iac-tf-gcs.name) = ["roles/storage.admin"]
  }
  iam_project_roles = {
    (var.project_id) = ["roles/compute.instanceAdmin.v1",
      "roles/compute.loadBalancerAdmin",
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
      "roles/container.admin",
      "roles/monitoring.admin",
      "roles/storage.admin",
      "roles/logging.admin",
      "roles/iam.serviceAccountUser",
      "roles/iam.serviceAccountAdmin",
      "roles/resourcemanager.projectIamAdmin",
      "roles/artifactregistry.admin"
    ]
  }
}

//state bucket
module "iac-tf-gcs" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs"
  project_id = var.project_id
  name       = "iac-core-tf"
  prefix     = local.prefix
  versioning = true
}

//state bucket
module "iac-outputs-gcs" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs"
  project_id = var.project_id
  name       = "iac-core-outputs"
  prefix     = local.prefix
  versioning = true
}

# Enable services
resource "google_project_service" "project" {
  for_each                   = toset(local.project_services)
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = true
}