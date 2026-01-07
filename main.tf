terraform {
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "Akademia"
    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "static-web-app-deployment"
    }
  }
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-cdn-frontdoor-web-privateLinkOrigin"
  location = "westeurope"
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  network_rules {
    default_action = "Allow"
  }

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = {
    environment = "example"
  }
}

resource "azurerm_storage_blob" "example" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "./app/index.html"
  content_type           = "text/html"
}

resource "azurerm_cdn_frontdoor_profile" "example" {
  name                     = "${var.prefix}-profile"
  resource_group_name      = azurerm_resource_group.example.name
  sku_name                 = "Premium_AzureFrontDoor"
  response_timeout_seconds = 120

  tags = {
    environment = "example"
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "example" {
  name                     = "${var.prefix}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Http"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "example" {
  name                     = "${var.prefix}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
  enabled                  = true
}

resource "azurerm_cdn_frontdoor_origin" "example" {
  name                          = "${var.prefix}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id
  enabled                       = true
  depends_on                    = [azurerm_storage_blob.example]

  certificate_name_check_enabled = true # Required for Private Link
  host_name                      = azurerm_storage_account.example.primary_web_host
  origin_host_header             = azurerm_storage_account.example.primary_web_host
  priority                       = 1
  weight                         = 500

  private_link {
    request_message        = "Request access for CDN Frontdoor Private Link Origin Storage Account Static Site Example"
    target_type            = "web"
    location               = azurerm_resource_group.example.location
    private_link_target_id = azurerm_storage_account.example.id
  }
}