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

###############################################################################
#                          Host and service projects                          #
###############################################################################

# the container.hostServiceAgentUser role is needed for GKE on shared VPC
# see: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc#grant_host_service_agent_role

module "project-host" {
  source          = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "hub-of-hubs"
  services        = concat(var.project_services, ["networkmanagement.googleapis.com"])
  shared_vpc_host_config = {
    enabled = true
  }
  iam = {
    "roles/owner" = var.owners_host_project
  }
}

module "project-svc-oshift-prod" {
  source          = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "proj-svc-oshift-prod"
  services        = var.project_services
  oslogin         = true
  oslogin_admins  = var.owners_oshift_prod
  shared_vpc_service_config = {
    host_project = module.project-host.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = ["cloudservices"]
    }
  }
  iam = {
    "roles/owner" = var.owners_oshift_prod
  }
}

module "project-svc-oshift-nonprod" {
  source          = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "proj-svc-oshift-nonprod"
  oslogin         = true
  oslogin_admins  = var.owners_oshift_nonprod
  services        = var.project_services
  shared_vpc_service_config = {
    host_project = module.project-host.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = ["cloudservices"]
    }
  }
}
module "project-gcve" {
  source          = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "proj-gcve"
  services = [
    "dns.googleapis.com",
    "compute.googleapis.com",
    "vmwareengine.googleapis.com",
    "servicedirectory.googleapis.com"
  ]
}

################################################################################
#                                  Networking                                  #
################################################################################

# subnet IAM bindings control which identities can use the individual subnets

module "vpc-shared" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc"
  project_id = module.project-host.project_id
  name       = "shared-vpc"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges.oshift_prod
      name          = "oshift-prod"
      region        = var.region
    },
    {
      ip_cidr_range = var.ip_ranges.oshift_nonprod
      name          = "oshift-nonprod"
      region        = var.region
    }
  ]
  subnet_iam = {
    "${var.region}/oshift-prod" = {
      "roles/compute.networkUser" = concat(var.owners_oshift_prod, [
        "serviceAccount:${module.project-svc-oshift-prod.service_accounts.cloud_services}",
      ])
    }
    "${var.region}/oshift-nonprod" = {
      "roles/compute.networkUser" = concat(var.owners_oshift_nonprod, [
        "serviceAccount:${module.project-svc-oshift-nonprod.service_accounts.cloud_services}",
      ])
    }
  }
}

module "vpc-shared-firewall" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall"
  project_id = module.project-host.project_id
  network    = module.vpc-shared.name
  default_rules_config = {
    admin_ranges = values(var.ip_ranges)
  }
}

module "nat" {
  source         = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = module.project-host.project_id
  region         = var.region
  name           = "vpc-shared"
  router_create  = true
  router_network = module.vpc-shared.name
}

/* module "vpn-1" {
  source       = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id   = var.project_id
  region       = var.region
  network      = var.vpc1.self_link
  name         = "net1-to-net-2"
  peer_gateway = { gcp = module.vpn-2.self_link }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        "10.0.0.0/8" = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-2" {
  source        = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id    = var.project_id
  region        = var.region
  network       = var.vpc2.self_link
  name          = "net2-to-net1"
  router_config = { asn = 64513 }
  peer_gateway  = { gcp = module.vpn-1.self_link }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-1.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-1.random_secret
      vpn_gateway_interface = 1
    }
  }
} */
