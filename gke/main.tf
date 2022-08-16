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

module "gke_cluster" {
  source                    = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster"
  project_id                = var.globals.project_id
  name                      = "${var.globals.prefix}-gke-cluster"
  location                  = var.cluster_location
  network                   = var.network.vpc.self_link
  subnetwork                = var.network.vpc.subnet_self_links["us-central1/gke-uc1"]
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32
  master_authorized_ranges = {
    internal-vms = var.network.admin_ranges[0]
  }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.network.vpc.subnet_secondary_ranges["us-central1/gke-uc1"].services
    master_global_access    = false
  }
  labels = {
    environment = var.globals.env
  }
}

module "cluster_nodepool_1" {
  source                      = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-nodepool"
  project_id                  = var.globals.project_id
  cluster_name                = module.gke_cluster.name
  location                    = var.nodepools[0].location
  name                        = var.nodepools[0].name
  node_service_account_create = true
}