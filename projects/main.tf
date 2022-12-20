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

/* module "nat" {
  source         = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = module.project-host.project_id
  region         = var.region
  name           = "vpc-shared"
  router_create  = true
  router_network = module.vpc-shared.name
} */


######## VPN #########
#VPN to on-prem
module "vpn_ha_onprem" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id = module.project-host.project_id
  region     = var.region
  network    = module.vpc-shared.name
  name       = "gcp-to-onprem"
  peer_gateway = {
    external = {
      redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
      interfaces      = ["8.8.8.8"] # on-prem router ip address
    }
  }
  router_config = { asn = 64514 }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range               = "169.254.1.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range               = "169.254.2.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 1
    }
  }
}

#VPN Gateway for hubs
resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  provider = google-beta
  region   = "us-central1"
  name     = "ha-vpn-gtw1"
  network  = "shared-vpc"
  project  = "${var.prefix}-hub-of-hubs"
}

/* #HA VPN to Itaka Hub
module "hub-to-itaka-vpn" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id = var.project_id
  network    = module.vpc-shared.self_link
  region     = var.region
  name       = "${var.prefix}-hub-to-itaka-vpn"
  # router is created and managed by the production VPN module
  # so we don't configure advertisements here
  router_config = {
    create = false
    name   = "${var.prefix}-cr-hub-to-itaka"
    asn    = 64514
  }
  peer_gateway = { gcp = module.itaka-to-hub-vpn.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = var.vpn_configs.itaka-vpn.asn
      }
      bgp_session_range     = "169.254.2.1/30"
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.2.6"
        asn     = var.vpn_configs.itaka-vpn.asn
      }
      bgp_session_range     = "169.254.2.5/30"
      vpn_gateway_interface = 1
    }
  }
}

module "itaka-to-hub-vpn" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id = var.project_id
  network    = module.dev-vpc.self_link
  region     = var.regions.r1
  name       = "${var.prefix}-dev-to-lnd-r1"
  router_config = {
    name = "${var.prefix}-dev-vpn-r1"
    asn  = var.vpn_configs.dev-r1.asn
    custom_advertise = {
      all_subnets = false
      ip_ranges   = coalesce(var.vpn_configs.dev-r1.custom_ranges, {})
      mode        = "CUSTOM"
    }
  }
  peer_gateway = { gcp = module.landing-to-dev-vpn-r1.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = var.vpn_configs.land-r1.asn
      }
      bgp_session_range     = "169.254.2.2/30"
      shared_secret         = module.landing-to-dev-vpn-r1.random_secret
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.2.5"
        asn     = var.vpn_configs.land-r1.asn
      }
      bgp_session_range     = "169.254.2.6/30"
      shared_secret         = module.landing-to-dev-vpn-r1.random_secret
      vpn_gateway_interface = 1
    }
  }
} */