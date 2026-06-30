data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  special = false
  numeric = true
}

locals {
  resource_group_name = "rg-${var.name_prefix}-${random_string.suffix.result}"
  search_service_name = substr("${var.name_prefix}${random_string.suffix.result}", 0, 60)
  index_name          = "hotels-index"
}

resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2021-04-01"
  name     = local.resource_group_name
  location = var.location
}

resource "azapi_resource" "search_service" {
  type      = "Microsoft.Search/searchServices@2023-11-01"
  parent_id = azapi_resource.resource_group.id
  name      = local.search_service_name
  location  = azapi_resource.resource_group.location

  body = {
    sku = {
      name = "basic"
    }
    properties = {
      replicaCount   = 1
      partitionCount = 1
      hostingMode    = "default"
      authOptions = {
        aadOrApiKey = {
          aadAuthFailureMode = "http401WithBearerChallenge"
        }
      }
    }
  }
}

# Look up the built-in data-plane role without depending on azurerm.
#
# Creating and reading an AI Search *index definition* (PUT/GET /indexes) is an object-
# management operation. Per the Azure AI Search RBAC matrix this requires "Search Service
# Contributor" - NOT "Search Index Data Contributor", which only grants document content
# read/write (load/query) and explicitly cannot modify or view object definitions.
data "azapi_resource_list" "role_definitions" {
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"

  response_export_values = {
    search_service_contributor_role_id = "value[?properties.roleName == 'Search Service Contributor'].id | [0]"
  }
}

resource "azapi_resource" "search_service_contributor" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  parent_id = azapi_resource.search_service.id
  name      = uuid()

  body = {
    properties = {
      principalId      = data.azapi_client_config.current.object_id
      roleDefinitionId = data.azapi_resource_list.role_definitions.output.search_service_contributor_role_id
    }
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "time_sleep" "rbac_propagation" {
  depends_on      = [azapi_resource.search_service_contributor]
  create_duration = var.rbac_propagation_delay
}

# Managed resource: create the AI Search index through the data plane.
resource "azapi_data_plane_resource" "index" {
  type      = "Microsoft.Search/searchServices/indexes@2024-07-01"
  parent_id = "${azapi_resource.search_service.name}.search.windows.net"
  name      = local.index_name

  body = {
    fields = [
      {
        name       = "hotelId"
        type       = "Edm.String"
        key        = true
        searchable = false
      },
      {
        name       = "hotelName"
        type       = "Edm.String"
        searchable = true
      },
      {
        name       = "category"
        type       = "Edm.String"
        searchable = true
        filterable = true
      }
    ]
  }

  depends_on = [time_sleep.rbac_propagation]
}

# New generic data source under test: read the index back through the data plane.
data "azapi_data_plane_resource" "index" {
  type      = "Microsoft.Search/searchServices/indexes@2024-07-01"
  parent_id = "${azapi_resource.search_service.name}.search.windows.net"
  name      = azapi_data_plane_resource.index.name

  response_export_values = {
    field_names = "fields[].name"
    key_field   = "fields[?key].name | [0]"
  }
}
