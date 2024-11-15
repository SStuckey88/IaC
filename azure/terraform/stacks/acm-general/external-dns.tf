# Create Service Principal for ExternalDNS
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azuread_application" "externaldns" {
  display_name = "${var.external_dns_namespace}ServiceApp"
  owners       = distinct(concat([data.azuread_client_config.current.object_id], var.additional_owner_ids))
}

resource "azuread_service_principal" "externaldns" {
  client_id                    = azuread_application.externaldns.client_id
  app_role_assignment_required = false
  owners                       = distinct(concat([data.azuread_client_config.current.object_id], var.additional_owner_ids))
  description                  = "Service Principal for ExternalDNS within on-prem Kubernetes"
}

resource "azuread_service_principal_password" "externaldns" {
  display_name         = "${var.external_dns_namespace}Password"
  service_principal_id = azuread_service_principal.externaldns.id
}

resource "azurerm_role_assignment" "externaldns_reader" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/dnszones/${var.public_domain_suffixes[0]}"
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.externaldns.object_id
}

resource "azurerm_role_assignment" "externaldns_contributor" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/dnszones/${var.public_domain_suffixes[0]}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.externaldns.object_id
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "externaldns_sp_keyid" {
  value = azuread_service_principal_password.externaldns.key_id
}

output "externaldns_sp_clientid" {
  value = azuread_application.externaldns.client_id
}

output "externaldns_sp_password" {
  value     = azuread_service_principal_password.externaldns.value
  sensitive = true
}

output "default_resource_group" {
  value = var.resource_group_name
}
