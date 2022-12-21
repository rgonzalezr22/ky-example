variable "vpn-pair" {
    description = "VPN configuration for gcp pair"
    type = object({
        gcp-a = object({
            asn = number
            project_id = string
            region = string
            vpc = string
            vpn-name = string
            custom_ranges = map(string)
            bgp = object({
                address-0 = string
                address-1 = string
            })
        })        
        gcp-b = object({
            asn = number
            project_id = string
            region = string
            vpc = string
            vpn-name = string
            custom_ranges = map(string)
            bgp = object({
                address-0 = string
                address-1 = string
            })
        })        
    })
}