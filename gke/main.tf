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
    master_ipv4_cidr_block  = "192.168.1.0/28" # var.network.vpc.subnet_secondary_ranges["us-central1/gke-uc1"].services
    master_global_access    = false
  }
  labels = {
    environment = var.globals.env
  }
  node_locations = local.cluster_node_locations
}

module "cluster_nodepool_1" {
  source                      = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-nodepool"
  for_each                    = { for index, np in var.nodepools : np.name => np }
  project_id                  = var.globals.project_id
  cluster_name                = module.gke_cluster.name
  location                    = var.cluster_location
  name                        = each.value.name
  node_service_account_create = true
}

module "bastion-vm" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/compute-vm"
  project_id = var.globals.project_id
  zone       = var.nodepools[0].location
  name       = "gke-bastion"
  network_interfaces = [{
    network    = var.network.vpc.self_link
    subnetwork = var.network.vpc.subnet_self_links["us-central1/gke-uc1"]
    nat        = false
    addresses  = null
  }]
  service_account = module.gke_bastion_sa.email
  instance_type = var.bastion.instance_type
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags = ["ssh"]
}

# Startup script for bastion host
/*
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
sudo apt-get install kubectl
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
gcloud container clusters get-credentials pugsite-dev-gke-cluster --zone us-central1-a --project lgke-app-gke
helm repo add bitnami https://charts.bitnami.com/bitnami
curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh
useradd -M spinaker
sudo bash InstallHalyard.sh --user spinaker
*/

# Sergice account for bastions
module "gke_bastion_sa" {
  source      = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account"
  project_id  = var.globals.project_id
  name        = "gke-bastion-sa"
  description = ""
  prefix      = var.globals.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam               = {}
  iam_storage_roles = {}
  iam_project_roles = {
    (var.globals.project_id) = [
      "roles/compute.instanceAdmin.v1",
      "roles/container.admin",
      "roles/storage.admin",
      "roles/logging.admin",
      "roles/iam.serviceAccountUser",
      "roles/iap.tunnelResourceAccessor"
    ]
  }
}
