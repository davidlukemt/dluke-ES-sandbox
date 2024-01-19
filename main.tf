terraform {
    required_providers {
        equinix = {
            source  = "equinix/equinix"
            version = "1.22.0"
        }
    }
}

## import Primary Network Edge Device for peering to Metal VRF
#data "equinix_network_device" "ne_dev_pri" {
#  uuid = var.network_edge_device_pri
#}

## import Secondary Network Edge Device for peering to Metal VRF
#data "equinix_network_device" "ne_dev_sec" {
#  uuid = var.network_edge_device_sec
#}

## create Metal VRF
resource "equinix_metal_vrf" "vrf_dallas_1" {
    description = "Core Network VRF in Dallas"
    name        = "dl-da-vrf-1"
    metro       = "da"
    ip_ranges   = ["172.28.0.0/20", "169.254.254.0/24"]
    project_id  = var.project_id
    local_asn = 4200000281
}

## create Fabric Connection tokens for VRF uplink
#resource "equinix_metal_connection" "da_vrf_vc1" {
#    name               = "tf-dl-da-vrf-1_to_NE"
#    project_id         = var.project_id
#    type               = "shared"
#    redundancy         = "redundant"
#    metro              = "da"
#    service_token_type = "z_side"
#    contact_email      = "dluke@equinix.com"
#}

## consume Fabric VC tokens to create connection to primary NE Device
#resource "equinix_fabric_connection" "vrf_to_ne_pri" {
#  name = "tf-dl-da-vrf-1_to_NE-Pri"
#  type = "EVPL_VC"
#  notifications {
#    type   = "ALL"
#    emails = ["dluke@equinix.com"]
#  }
#  bandwidth = 50
#  a_side {
#    access_point {
#      type = "VD"
#      virtual_device {
#        type = "EDGE"
#        uuid = data.equinix_network_device.ne_dev_pri.id
#      }
#      interface {
#        type = "NETWORK"
#        id = 5
#      }
#    }
#  }
#  z_side {
#    service_token {
#      uuid = equinix_metal_connection.da_vrf_vc1.service_tokens[0].id
#    }
#  }
#}

## consume Fabric VC tokens to create connection to secondary NE Device
#resource "equinix_fabric_connection" "vrf_to_ne_sec" {
#  name = "tf-dl-da-vrf-1_to_NE-Sec"
#  type = "EVPL_VC"
#  notifications {
#    type   = "ALL"
#    emails = ["dluke@equinix.com"]
#  }
#  bandwidth = 50
#  a_side {
#    access_point {
#      type = "VD"
#      virtual_device {
#        type = "EDGE"
#        uuid = data.equinix_network_device.ne_dev_sec.id
#      }
#      interface {
#        type = "NETWORK"
#        id = 5
#      }
#    }
#  }
#  z_side {
#    service_token {
#      uuid = equinix_metal_connection.da_vrf_vc1.service_tokens[1].id
#    }
#  }
#}

#resource "equinix_ecx_l2_connection" "vrf_to_ne_pri" {
#  name                = "tf-dl-da-vrf-1_to_NE-Pri"
#  device_uuid         = var.network_edge_device_pri
#  device_interface_id = 5
#  speed               = 100
#  speed_unit          = "MB"
#  notifications       = ["dluke@equinix.com"]
#  zside_service_token = equinix_metal_connection.da_vrf_vc1.service_tokens[0].id
#}
#
#resource "equinix_ecx_l2_connection" "vrf_to_ne_sec" {
#  name                = "tf-dl-da-vrf-1_to_NE-Sec"
#  device_uuid         = var.network_edge_device_sec
#  device_interface_id = 5
#  speed               = 100
#  speed_unit          = "MB"
#  notifications       = ["dluke@equinix.com"]
#  zside_service_token = equinix_metal_connection.da_vrf_vc1.service_tokens[1].id
#  }

## create VCs with details for VRF uplink
#resource "equinix_metal_virtual_circuit" "da_vrf_vc_pri" {
#  connection_id        = equinix_metal_connection.da_vrf_vc1.id
#  project_id           = var.project_id
#  port_id              = equinix_metal_connection.da_vrf_vc1.ports[0].id
#  vrf_id               = equinix_metal_vrf.vrf_dallas_1.id
#  peer_asn             = 65534
#  subnet               = "169.254.254.0/30"
#  customer_ip          = "169.254.254.1"
#  metal_ip             = "169.254.254.2"
#  md5                  = "metalVRFftw1"
#}

## create VCs with details for VRF uplink
#resource "equinix_metal_virtual_circuit" "da_vrf_vc_sec" {
#  connection_id        = equinix_metal_connection.da_vrf_vc1.id
#  project_id           = var.project_id
#  port_id              = equinix_metal_connection.da_vrf_vc1.ports[1].id
#  vrf_id               = equinix_metal_vrf.vrf_dallas_1.id
#  peer_asn             = 65534
#  subnet               = "169.254.254.4/30"
#  customer_ip          = "169.254.254.5"
#  metal_ip             = "169.254.254.6"
#  md5                  = "metalVRFftw1"
#}

# create IP reservation for VRF Gateway
resource "equinix_metal_reserved_ip_block" "ip_block_dallas_1" {
    project_id = var.project_id
    metro      = "da"
    type       = "vrf"
    vrf_id     = equinix_metal_vrf.vrf_dallas_1.id
    network    = "172.28.0.0"
    cidr       = 24
}

# create vlan for VRF network
resource "equinix_metal_vlan" "vlan_dallas_1" {
    description = "ES-DA-VRF_infra"
    metro       = "da"
    project_id  = var.project_id
    vxlan       = 2800
}

# create a VRF gateway
resource "equinix_metal_gateway" "gateway_dallas_1" {
    project_id        = var.project_id
    vlan_id           = equinix_metal_vlan.vlan_dallas_1.id
    ip_reservation_id = equinix_metal_reserved_ip_block.ip_block_dallas_1.id
}

