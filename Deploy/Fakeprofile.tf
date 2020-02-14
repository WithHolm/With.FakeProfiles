provider "azurerm" {
  version = "=1.44.0"
}

variable "Pipeline" {
  type    = string
  default = "dev"
}

variable "storage_tables" {
  type    = list(string)
  default = ["config", "faces", "progress", "import"]
}

variable "storage_queues" {
  type    = list(string)
  default = []
}

variable "storage_containers" {
  type    = list(string)
  default = ["pictures"]
}

locals {
  projectName = "fakeprofile"
  location    = "West Europe"
}


resource "azurerm_resource_group" "fake" {
  name     = join("-", [var.Pipeline, local.projectName, "rg"])
  location = local.location
}

# Storage
resource "azurerm_storage_account" "fake" {
  resource_group_name       = azurerm_resource_group.fake.name
  name                      = lower(join("", [var.Pipeline, local.projectName, "sa"]))
  location                  = azurerm_resource_group.fake.location
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = true
}

# 1 container for each inputelement
resource "azurerm_storage_container" fake {
  count                 = length(var.storage_containers)
  name                  = var.storage_containers[count.index]
  storage_account_name  = azurerm_storage_account.fake.name
  container_access_type = "private"
}

# 1 Table for each inputelement
resource "azurerm_storage_table" fake {
  count                 = length(var.storage_tables)
  name                  = var.storage_tables[count.index]
  storage_account_name  = azurerm_storage_account.fake.name
}

# 1 queue for each inputelement
resource "azurerm_storage_queue" fake {
  count                 = length(var.storage_queues)
  name                  = var.storage_queues[count.index]
  storage_account_name  = azurerm_storage_account.fake.name
}

#App service
resource "azurerm_app_service_plan" "fake" {
  resource_group_name = azurerm_resource_group.fake.name
  name                = lower(join("-", [var.Pipeline, local.projectName, "asp"]))
  location            = azurerm_resource_group.fake.location
  kind                = "FunctionApp"
  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_function_app" "fake" {
  resource_group_name       = azurerm_resource_group.fake.name
  name                      = lower(join("-", [var.Pipeline, local.projectName, "fn"]))
  location                  = azurerm_resource_group.fake.location
  app_service_plan_id       = azurerm_app_service_plan.fake.id
  storage_connection_string = azurerm_storage_account.fake.primary_connection_string
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME            = "Powershell"
    FUNCTIONS_EXTENSION_VERSION         = "~2"
    AzureWebJobsStorage                 = azurerm_storage_account.fake.primary_connection_string
    API_Location_Face                   = azurerm_resource_group.fake.location
    API_SubscriptionKey_Face            = azurerm_cognitive_account.fake.primary_access_key
    PSWorkerInProcConcurrencyUpperBound = 10
  }
  site_config {
    use_32_bit_worker_process = true
  }
}

resource "azurerm_cognitive_account" "fake" {
  name                = lower(join("-", [var.Pipeline, local.projectName, "cs"]))
  location            = azurerm_resource_group.fake.location
  resource_group_name = azurerm_resource_group.fake.name
  kind                = "Face"
  sku_name            = "S0"
}

output "FunctionAppName" {
  value = azurerm_function_app.fake.name
}
output "ResourceGroupName" {
  value = azurerm_resource_group.fake.name
}







