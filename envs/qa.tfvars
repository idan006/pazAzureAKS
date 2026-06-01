environment  = "qa"
location     = "eastus"
project_name = "azure-hub-spoke-aks"

hub_address_space = ["10.0.0.0/16"]
hub_subnets = {
  AzureFirewallSubnet = {
    address_prefixes = ["10.0.0.0/26"]
  }
  AzureBastionSubnet = {
    address_prefixes = ["10.0.0.64/26"]
  }
  ApplicationGatewaySubnet = {
    address_prefixes = ["10.0.1.0/24"]
  }
  SharedServicesSubnet = {
    address_prefixes = ["10.0.2.0/24"]
  }
}

spoke_address_space = ["10.20.0.0/16"]
spoke_subnets = {
  aks-subnet = {
    address_prefixes = ["10.20.1.0/24"]
  }
  app-subnet = {
    address_prefixes = ["10.20.2.0/24"]
  }
  private-endpoint-subnet = {
    address_prefixes = ["10.20.3.0/24"]
  }
}

nginx_ingress_private_ip = "10.20.1.100"
aks_node_count           = 2
aks_vm_size              = "Standard_D4s_v5"

tags = {
  owner       = "platform"
  cost_center = "shared"
  workload    = "hello-world"
}
