output "resource_group_name" {
  description = "Resource Group administrado por esta configuração."
  value       = azurerm_resource_group.demo.name
}

output "acr_login_server" {
  description = "Login server do ACR configurado para a aplicação."
  value       = azurerm_container_registry.demo.login_server
}

output "aks_name" {
  description = "Nome do cluster AKS administrado por esta configuração."
  value       = azurerm_kubernetes_cluster.demo.name
}
