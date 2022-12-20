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

variable "auto_create_network" {
  description = "Whether to create the default network for the project."
  type        = bool
  default     = false
}

variable "billing_account_id" {
  description = "Billing account id."
  type        = string
  default     = "01E654-CF45ED-8F2561"
}

variable "ip_ranges" {
  description = "Subnet IP CIDR ranges."
  type        = map(string)
  default = {
    oshift_prod    = "10.0.16.0/24"
    oshift_nonprod = "10.0.32.0/24"
  }
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "owners_oshift_prod" {
  description = "OShift Prod project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "owners_oshift_nonprod" {
  description = "Oshift Non Prod project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "owners_host_project" {
  description = "Host project for Hub of Hubs owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "iap.googleapis.com",
    "cloudbuild.googleapis.com",
    "dns.googleapis.com",
    "stackdriver.googleapis.com"
  ]
}

variable "region" {
  description = "Region used."
  type        = string
  default     = "us-central1"
}

variable "root_node" {
  description = "Hierarchy node where projects will be created, 'organizations/org_id' or 'folders/folder_id'."
  type        = string
  default     = "organizations/737340371464"
}

variable "name" {
  description = "VPN Gateway name (if an existing VPN Gateway is not used), and prefix used for dependent resources."
  type        = string
  default     = "vpn-gtw-1"
}

variable "shared_vpc_host_config" {
  description = "Configures this project as a Shared VPC host project (mutually exclusive with shared_vpc_service_project)."
  type = object({
    enabled          = bool
    service_projects = optional(list(string), [])
  })
  default = null
}

variable "project_id" {
  description = "Project where resources will be created."
  type        = string
  default     = "sandbox-rgr"
}

variable "vpn_gateway_create" {
  description = "Create HA VPN Gateway."
  type        = bool
  default     = true
}

variable "vpn_configs" {
  description = "VPN configurations."
  type = map(object({
    asn           = number
    custom_ranges = map(string)
  }))
  default = {
    hub-hubs-vpn = {
      asn = 64513
      custom_ranges = {
        "10.0.0.0/8" = "internal default"
      }
    }
    itaka-vpn = {
      asn           = 64514
      custom_ranges = null
    }
    dc-vpn = {
      asn           = 64515
      custom_ranges = null
    }
    avicena-vpn = {
      asn           = 64516
      custom_ranges = null
    }
  }
}