resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-cdn-frontdoor-web-privateLinkOrigin"
  location = var.location
  tags     = var.tags
}

module "storage" {
  source = "./modules/storage"

  prefix              = var.prefix
  location            = var.location
  tags                = var.tags
  resource_group_name = azurerm_resource_group.example.name
}

module "cdn" {
  source = "./modules/cdn"

  prefix                   = var.prefix
  location                 = var.location
  resource_group_name      = azurerm_resource_group.example.name
  tags                     = var.tags
  storage_account_id       = module.storage.id
  storage_primary_web_host = module.storage.primary_web_host
}