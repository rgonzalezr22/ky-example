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
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "dns.googleapis.com",
    "container.googleapis.com",
    "stackdriver.googleapis.com",
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

/* variable "peer_gateway" {
  description = "Configuration of the (external or GCP) peer gateway."
  type = object({
    external = optional(object({
      redundancy_type = string
      interfaces      = list(string)
    }))
    gcp = optional(string)
  })
  nullable = false
  validation {
    condition     = (var.peer_gateway.external != null) != (var.peer_gateway.gcp != null)
    error_message = "Peer gateway configuration must define exactly one between `external` and `gcp`."
  }
} */
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

/* variable "router_config" {
  description = "Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router."
  type = object({
    create    = optional(bool, true)
    asn       = number
    name      = optional(string)
    keepalive = optional(number)
    custom_advertise = optional(object({
      all_subnets = bool
      ip_ranges   = map(string)
    }))
  })
  nullable = false
}

variable "tunnels" {
  description = "VPN tunnel configurations."
  type = map(object({
    bgp_peer = object({
      address        = string
      asn            = number
      route_priority = optional(number, 1000)
      custom_advertise = optional(object({
        all_subnets          = bool
        all_vpc_subnets      = bool
        all_peer_vpc_subnets = bool
        ip_ranges            = map(string)
      }))
    })
    # each BGP session on the same Cloud Router must use a unique /30 CIDR
    # from the 169.254.0.0/16 block.
    bgp_session_range               = string
    ike_version                     = optional(number, 2)
    peer_external_gateway_interface = optional(number)
    router                          = optional(string)
    shared_secret                   = optional(string)
    vpn_gateway_interface           = number
  }))
  default  = {}
  nullable = false
}

variable "vpn_gateway" {
  description = "HA VPN Gateway Self Link for using an existing HA VPN Gateway. Ignored if `vpn_gateway_create` is set to `true`."
  type        = string
  default     = null
}

variable "vpn_gateway_create" {
  description = "Create HA VPN Gateway."
  type        = bool
  default     = true
} */