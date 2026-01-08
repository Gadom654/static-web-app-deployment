resource "azurerm_cdn_frontdoor_profile" "example" {
  name                     = "${var.prefix}-profile"
  resource_group_name      = var.resource_group_name
  sku_name                 = "Standard_AzureFrontDoor"
  response_timeout_seconds = 120

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "example" {
  name                                                      = "${var.prefix}-origin-group"
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.example.id
  session_affinity_enabled                                  = false
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

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_origin" "example" {
  name                          = "${var.prefix}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id
  enabled                       = true

  certificate_name_check_enabled = true # Required for Private Link
  host_name                      = var.storage_primary_web_host
  origin_host_header             = var.storage_primary_web_host
  priority                       = 1
  weight                         = 500

}

resource "azurerm_cdn_frontdoor_route" "example" {
  name                          = "${var.prefix}-example-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.example.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.example.id]
  enabled                       = true

  forwarding_protocol    = "MatchRequest"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

}