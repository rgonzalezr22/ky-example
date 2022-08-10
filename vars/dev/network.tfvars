region = "us-central1"

subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "gke-uc1"
      region        = "us-central1"
      secondary_ip_range = {
        pods     = "172.16.0.0/20"
        services = "192.168.0.0/24"
      }
    },
    {
      ip_cidr_range = "10.0.16.0/24"
      name          = "gke-ue4"
      region        = "us-east4"
      secondary_ip_range = {}
    }
  ]