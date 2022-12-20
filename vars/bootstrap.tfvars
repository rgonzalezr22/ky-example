prefix = "rgrsite"
project_id = "sandbox-rgr"
env = "dev"
cicd_repository = "rgonzalezr22/ky-example"

federated_identity_providers = {
  github-fip = {
    attribute_condition = "attribute.repository_owner==\"imp14a\""
    issuer              = "github"
    custom_settings     = null
  }
}