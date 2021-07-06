output "kubernetes_cluster_id" {
  value = module.aks.kubernetes_cluster_id
}

output "kubeconfig" {
  value = module.aks.kubeconfig
}

output "cluster_resource_group_name" {
  value = azurerm_resource_group.aks.name
}

output "cluster_node_resource_group_name" {
  value = module.aks.node_resource_group_name
}

output "aks_principal_id" {
  value = azurerm_user_assigned_identity.aks.principal_id
}

output "kubernetes_identity" {
  value = module.aks.kubernetes_identity
}

output "cluster_fqdn" {
  value = module.aks.fqdn
}
