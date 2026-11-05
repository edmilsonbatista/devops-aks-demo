variable "subscription_id" {
  description = "ID da assinatura Azure que contém os recursos importados."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group existente que contém o ACR e o AKS desta demo."
  type        = string
  default     = "rg-devops-aks-demo"
}

variable "location" {
  description = "Região Azure dos recursos existentes."
  type        = string
  default     = "eastus"
}

variable "acr_name" {
  description = "Nome do ACR associado ao AKS e usado pelo workflow GitHub Actions."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "acr_name deve conter de 5 a 50 letras minúsculas e números."
  }
}

variable "acr_sku" {
  description = "SKU atualmente configurado no ACR existente."
  type        = string
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku deve ser Basic, Standard ou Premium."
  }
}

variable "acr_admin_enabled" {
  description = "Estado atual do usuário administrador do ACR."
  type        = bool
}

variable "acr_pull_role_assignment_guid" {
  description = "GUID da atribuição AcrPull existente associada à identidade kubelet do AKS."
  type        = string
}

variable "aks_name" {
  description = "Nome do cluster AKS existente."
  type        = string
  default     = "aksdevopsdemo"
}

variable "aks_dns_prefix" {
  description = "DNS prefix atual do AKS."
  type        = string
  default     = "aksdevopsd-rg-devops-aks-de-a4091a"
}

variable "aks_kubernetes_version" {
  description = "Versão Kubernetes atual do AKS."
  type        = string
}

variable "aks_sku_tier" {
  description = "Tier atual do plano de controle AKS."
  type        = string
  default     = "Free"
}

variable "aks_identity_type" {
  description = "Tipo de identidade gerenciada atual do AKS."
  type        = string
  default     = "SystemAssigned"
}

variable "aks_linux_admin_username" {
  description = "Usuário administrador Linux já configurado no AKS."
  type        = string
  default     = "azureuser"
}

variable "aks_ssh_public_key" {
  description = "Chave SSH pública existente no perfil Linux do AKS."
  type        = string
}

variable "node_pool_name" {
  description = "Nome do node pool padrão atual do AKS."
  type        = string
  default     = "nodepool1"
}

variable "node_count" {
  description = "Quantidade atual de nodes no node pool padrão."
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "SKU atual das VMs do node pool padrão."
  type        = string
  default     = "Standard_D2s_v4"
}
