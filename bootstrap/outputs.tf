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

resource "google_storage_bucket_object" "providers" {
  bucket  = module.iac-outputs-gcs.name
  name    = "templates/backend.tf"
  content = local.backend
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = module.iac-outputs-gcs.name
  name    = "tfvars/bootstrap.auto.tfvars.json"
  content = jsonencode(local.tfvars_globals)
}

output "globals" {
  value = local.tfvars_globals
}


/*resource "null_resource" "health_check" {

 provisioner "local-exec" {
    
    command = "/bin/bash healthcheck.sh"
  }
}*/