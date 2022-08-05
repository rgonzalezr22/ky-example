

prefix = "agus"
project_id = "lgke-app-gke"
env = "dev"
cicd_repository = "imp14a/terraform-gcp-puginfra"

federated_identity_providers = {
  github-fip = {
    attribute_condition = "attribute.repository_owner==\"imp14a\""
    issuer              = "github"
    custom_settings     = null
  }
}