resource "azurerm_role_assignment" "cluster_users" {
  for_each = toset(var.cluster_users)

  scope                = module.aks.kubernetes_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "cluster_admins" {
  for_each = toset(var.cluster_admins)

  scope                = module.aks.kubernetes_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = each.value
}
