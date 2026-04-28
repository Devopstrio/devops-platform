provider "azurerm" {
  features {}
}

provider "aws" {
  region = var.aws_region
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-${var.project_name}-platform-${var.environment}"
  location = var.location
}

# --- Internal Developer Platform Hub (AKS) ---

resource "azurerm_kubernetes_cluster" "platform_k8s" {
  name                = "aks-platform-iq-${var.environment}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  dns_prefix          = "platform-k8s"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}

# --- Platform State Metadata (Postgres) ---

resource "azurerm_postgresql_flexible_server" "metadata" {
  name                   = "psql-platform-metadata-${var.environment}"
  resource_group_name    = azurerm_resource_group.platform.name
  location               = azurerm_resource_group.platform.location
  version                = "13"
  administrator_login    = "platformadmin"
  administrator_password = var.db_password
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2ds_v4"
}

# --- Multi-Cloud Shared Services (AWS S3 Persistence) ---

resource "aws_s3_bucket" "shared_assets" {
  bucket = "db-platform-shared-assets-${var.environment}"
}

# --- Global Ingress Controller (Azure Application Gateway) ---

resource "azurerm_application_gateway" "ingress" {
  name                = "agw-platform-ingress-${var.environment}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = var.public_ip_id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                        = "rule"
    rule_type                   = "Basic"
    http_listener_name          = "listener"
    backend_address_pool_name   = "backend-pool"
    backend_http_settings_name  = "http-settings"
    priority                    = 1
  }
}
