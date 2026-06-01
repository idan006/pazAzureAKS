resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name}-waf-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
    request_body_check          = true
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = var.zones
  tags                = var.tags
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  backend_address_pool {
    name         = "nginx-ingress"
    ip_addresses = var.backend_ip_addresses
    fqdns        = var.backend_fqdns
  }

  backend_http_settings {
    name                  = "nginx-http"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_names                     = var.host_names
  }

  request_routing_rule {
    name                       = "http-to-nginx"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "nginx-ingress"
    backend_http_settings_name = "nginx-http"
    priority                   = 100
  }
}
