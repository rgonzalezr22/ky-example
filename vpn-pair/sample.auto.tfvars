vpn-pair = {
    gcp-a = {
        asn = 64513
        project_id = "hub-hub-project"
        region = "europe-west1"
        vpc = "hub-hub-vpc"
        vpn-name = "hub-hub-vpn"
        custom_ranges = {
            "10.0.9.0/24" = "default"
        }
        bgp = {
            address-0 = "169.254.1.1"
            address-1 = "169.254.2.1"
        }
    }

    gcp-b = {
        asn = 64514
        project_id = "itaka-hub-project"
        region = "europe-west1"
        vpc = "itaka-hub-vpc"
        vpn-name = "itaka-hub-vpn"
        custom_ranges = {
            "10.0.11.0/24" = "default"
        }
        bgp = {
            address-0 = "169.254.1.2"
            address-1 = "169.254.2.2"
        }
    }
}