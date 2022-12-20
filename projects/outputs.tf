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

output "projects" {
  description = "Project ids."
  value = {
    proj-hub-host-project   = module.project-host.project_id
    proj-svc-oshift-prod    = module.project-svc-oshift-prod.project_id
    proj-svc-oshift-nonprod = module.project-svc-oshift-nonprod.project_id
  }
}

output "vpc" {
  description = "Hub of Hubs Shared VPC"
  value = {
    name    = module.vpc-shared.name
    subnets = module.vpc-shared.subnet_ips
  }
}

/* 
output "bgp_peers" {
  description = "BGP peer resources."
  value = {
    for k, v in google_compute_router_peer.bgp_peer : k => v
  }
}

output "external_gateway" {
  description = "External VPN gateway resource."
  value       = one(google_compute_external_vpn_gateway.external_gateway[*])
}

output "gateway" {
  description = "VPN gateway resource (only if auto-created)."
  value       = one(google_compute_ha_vpn_gateway.ha_gateway[*])
}

output "name" {
  description = "VPN gateway name (only if auto-created). ."
  value       = one(google_compute_ha_vpn_gateway.ha_gateway[*].name)
}

output "random_secret" {
  description = "Generated secret."
  value       = local.secret
}

output "router" {
  description = "Router resource (only if auto-created)."
  value       = one(google_compute_router.router[*])
}

output "router_name" {
  description = "Router name."
  value       = local.router
}

output "self_link" {
  description = "HA VPN gateway self link."
  value       = local.vpn_gateway
}

output "tunnel_names" {
  description = "VPN tunnel names."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.tunnels[name].name, null)
  }
}

output "tunnel_self_links" {
  description = "VPN tunnel self links."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.tunnels[name].self_link, null)
  }
}

output "tunnels" {
  description = "VPN tunnel resources."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.tunnels[name], null)
  }
} */