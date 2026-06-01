resource "azurerm_public_ip" "this" {
  count = var.public_ip_enabled ? 1 : 0

  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tunneling_enabled   = true
  ip_connect_enabled  = true
  file_copy_enabled   = true
  copy_paste_enabled  = true
  scale_units         = var.scale_units
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = var.public_ip_enabled ? azurerm_public_ip.this[0].id : null
  }
}
