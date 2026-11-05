resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "demo" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
}

resource "azurerm_kubernetes_cluster" "demo" {
  name                   = var.aks_name
  location               = azurerm_resource_group.demo.location
  resource_group_name    = azurerm_resource_group.demo.name
  dns_prefix             = var.aks_dns_prefix
  kubernetes_version     = var.aks_kubernetes_version
  sku_tier               = var.aks_sku_tier
  oidc_issuer_enabled    = true
  local_account_disabled = false

  default_node_pool {
    name                 = var.node_pool_name
    node_count           = var.node_count
    vm_size              = var.node_vm_size
    max_pods             = 250
    os_disk_size_gb      = 128
    os_disk_type         = "Managed"
    os_sku               = "Ubuntu"
    type                 = "VirtualMachineScaleSets"
    auto_scaling_enabled = false

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = var.aks_identity_type
  }

  linux_profile {
    admin_username = var.aks_linux_admin_username

    ssh_key {
      key_data = var.aks_ssh_public_key
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "azure"
    outbound_type       = "loadBalancer"
    load_balancer_sku   = "standard"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.demo.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.demo.kubelet_identity[0].object_id
}

# Estes imports associam recursos Azure existentes ao estado do Terraform.
# Revise o plano de importação antes de aplicar.
import {
  to = azurerm_resource_group.demo
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
}

import {
  to = azurerm_container_registry.demo
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"
}

import {
  to = azurerm_kubernetes_cluster.demo
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${var.aks_name}"
}

import {
  to = azurerm_role_assignment.aks_acr_pull
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}/providers/Microsoft.Authorization/roleAssignments/${var.acr_pull_role_assignment_guid}"
}
