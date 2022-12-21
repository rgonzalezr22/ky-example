data "google_compute_network" "gcp-a-vpc" {
  project = var.vpn-pair.gcp-a.project_id
  name = var.vpn-pair.gcp-a.vpc
}

module "vpn-a-to-b" {
  source       = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id   = var.vpn-pair.gcp-a.project_id
  region       = var.vpn-pair.gcp-a.region
  network      = data.google_compute_network.gcp-a-vpc.self_link
  name         = var.vpn-pair.gcp-a.vpn-name
  peer_gateway = { gcp = module.vpn-b-to-a.self_link }
  router_config = {
    asn = var.vpn-pair.gcp-a.asn
    custom_advertise = {
      all_subnets = true
      ip_ranges = var.vpn-pair.gcp-a.custom_ranges
    }
  }
  tunnels = {
    remote-0 = {
      bgp_session_range     = "${var.vpn-pair.gcp-a.bgp.address-0}/30"
      vpn_gateway_interface = 0
      bgp_peer = {
        address = var.vpn-pair.gcp-b.bgp.address-0
        asn     = var.vpn-pair.gcp-b.asn
      }
    }
    remote-1 = {
      bgp_session_range     = "${var.vpn-pair.gcp-a.bgp.address-1}/30"
      vpn_gateway_interface = 1
      bgp_peer = {
        address = var.vpn-pair.gcp-b.bgp.address-1
        asn     = var.vpn-pair.gcp-b.asn
      }
    }
  }
}

data "google_compute_network" "gcp-b-vpc" {
  project = var.vpn-pair.gcp-b.project_id
  name = var.vpn-pair.gcp-b.vpc
}

module "vpn-b-to-a" {
  source       = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id   = var.vpn-pair.gcp-b.project_id
  region       = var.vpn-pair.gcp-b.region
  network      = data.google_compute_network.gcp-b-vpc.self_link
  name         = var.vpn-pair.gcp-b.vpn-name
  peer_gateway = { gcp = module.vpn-a-to-b.self_link }
  router_config = {
    asn = var.vpn-pair.gcp-b.asn
    custom_advertise = {
      all_subnets = true
      ip_ranges = var.vpn-pair.gcp-b.custom_ranges
    }
  }
  tunnels = {
    remote-0 = {
      bgp_session_range     = "${var.vpn-pair.gcp-b.bgp.address-0}/30"
      vpn_gateway_interface = 0
      shared_secret         = module.vpn-a-to-b.random_secret
      bgp_peer = {
        address = var.vpn-pair.gcp-a.bgp.address-0
        asn     = var.vpn-pair.gcp-a.asn
      }
    }
    remote-1 = {
      bgp_session_range     = "${var.vpn-pair.gcp-b.bgp.address-1}/30"
      vpn_gateway_interface = 1
      shared_secret         = module.vpn-a-to-b.random_secret
      bgp_peer = {
        address = var.vpn-pair.gcp-a.bgp.address-1
        asn     = var.vpn-pair.gcp-a.asn
      }
    }
  }
}
