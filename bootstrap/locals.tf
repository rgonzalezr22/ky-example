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

locals {
  prefix = join("-", compact([var.prefix, var.env]))
  project_services = [
    "cloudresourcemanager.googleapis.com",
    "iap.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "dns.googleapis.com"
  ]
  identity_providers_defs = {
    # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
    github = {
      attribute_mapping = {
        "google.subject"             = "assertion.sub"
        "attribute.sub"              = "assertion.sub"
        "attribute.actor"            = "assertion.actor"
        "attribute.repository"       = "assertion.repository"
        "attribute.repository_owner" = "assertion.repository_owner"
        "attribute.ref"              = "assertion.ref"
      }
      issuer_uri       = "https://token.actions.githubusercontent.com"
      principal_tpl    = "principal://iam.googleapis.com/%s/subject/repo:%s:ref:refs/heads/%s"
      principalset_tpl = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
  }
  identity_providers = {
    for k, v in var.federated_identity_providers : k => merge(
      v,
      lookup(local.identity_providers_defs, v.issuer, {})
    )
  }

  # Outputs
  _tpl_backend = "${path.module}/templates/backend.tf.tpl"
  backend = templatefile(local._tpl_backend, {
    bucket  = module.iac-tf-gcs.name
    sa      = module.iac-tf-sa.email
    project = var.project_id
  })

  tfvars_globals = {
    globals = {
      project_id     = var.project_id
      project_number = data.google_project.project.number
      prefix         = local.prefix
      env            = var.env
      output_bucket  = module.iac-outputs-gcs.name
    }
  }

}