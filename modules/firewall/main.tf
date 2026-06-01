resource "azurerm_public_ip" "this" {
  count = var.public_ip_enabled ? 1 : 0

  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  name                = "${var.name}-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_tier

  dns {
    proxy_enabled = true
  }

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "baseline" {
  name               = "${var.name}-baseline-rcg"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  network_rule_collection {
    name     = "egress-foundation"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-dns-http-https-ntp"
      protocols             = ["TCP", "UDP"]
      source_addresses      = var.source_cidrs
      destination_addresses = ["*"]
      destination_ports     = ["53", "80", "443", "123"]
    }
  }
}

resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = var.public_ip_enabled ? azurerm_public_ip.this[0].id : null
  }
}
