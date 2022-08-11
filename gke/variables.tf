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

variable "globals" {
  type = object({
    env            = string,
    output_bucket  = string,
    prefix         = string,
    project_id     = string,
    project_number = string
  })
}

variable "network" {
  type = object({
    vpc = object({
      name                    = string,
      self_link               = string,
      subnet_ips              = string,
      subnet_regions          = string,
      subnet_secondary_ranges = any,
      subnet_self_links       = any,
    })
    region       = string
    admin_ranges = list(string)
  })
}

variable "nodepools" {
  type = list(object({
    location = string,
    name     = string
  }))
}
variable "cluster_location" {
  type = string
}