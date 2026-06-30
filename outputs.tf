output "resource_group_name" {
  description = "Resource group created for the demo."
  value       = azapi_resource.resource_group.name
}

output "search_service_name" {
  description = "Globally unique Azure AI Search service name."
  value       = azapi_resource.search_service.name
}

output "index_body" {
  description = "Full AI Search index response read by data.azapi_data_plane_resource."
  value       = data.azapi_data_plane_resource.index.body
}

output "index_field_names" {
  description = "Projected field names from response_export_values."
  value       = data.azapi_data_plane_resource.index.output.field_names
}

output "index_key_field" {
  description = "Projected key field from response_export_values."
  value       = data.azapi_data_plane_resource.index.output.key_field
}
