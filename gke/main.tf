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

module "gke-cluster" {
  source                    = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster"
  project_id                = var.project_id
  name                      = "pugsite-cluster"
  location                  = "europe-west1-b"
  network                   = var.vpc.self_link
  subnetwork                = var.subnet.self_link
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32
  master_authorized_ranges = {
    internal-vms = "10.0.0.0/8"
  }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "192.168.0.0/28"
    master_global_access    = false
  }
  labels = {
    environment = "dev"
  }
}

module "cluster-1-nodepool-1" {
  source                      = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-nodepool"
  project_id                  = var.project_id
  cluster_name                = "cluster-1"
  location                    = "europe-west1-b"
  name                        = "nodepool-1"
}