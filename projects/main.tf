module "host-project" {
  source = "./fabric/modules/project"
  name   = "my-host-project"
  shared_vpc_host_config = {
    enabled = true
  }
}

module "service-project" {
  source = "./fabric/modules/project"
  name   = "my-service-project"
  shared_vpc_service_config = {
    attach       = true
    host_project = module.host-project.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/vpcaccess.user" = [
        "cloudrun"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
    /*org_policies = {
        "compute.disableGuestAttributesAccess" = {
      enforce = true
    }
    "constraints/compute.skipDefaultNetworkCreation" = {
      enforce = true
    }
    "iam.disableServiceAccountKeyCreation" = {
      enforce = true
    }
    }*/
  }
}