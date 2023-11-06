###########################################################
# CLUSTER RESOURCE GROUP
###########################################################
# Resource group to store cluster-related resource.
###########################################################
resource "azurerm_resource_group" "aks" {
  name     = "${var.prefix}-rg-aks"
  location = var.location
  tags     = local.tags
}

# The principal running the terraform needs to be
# an "Owner" on the resource group in order
# to deploy resources and assign permission.
resource "azurerm_role_assignment" "aks_rg_owner_ci" {
  scope                = azurerm_resource_group.aks.id
  role_definition_name = "Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign ownership permissions to the principals
# defined in the `resource_owners` variable.
# This is typically an Azure AD group contain
# administrative users.
resource "azurerm_role_assignment" "aks_rg_owner_resource_owners" {
  for_each = toset(var.resource_owners)

  scope                = azurerm_resource_group.aks.id
  role_definition_name = "Owner"
  principal_id         = each.value
}

###########################################################
# CLUSTER IDENTITY
###########################################################
# Create a user assigned identity for use
# by the AKS cluster. Permissions required
# by the cluster:
#   - Subnet join on subnets where nodes are located
#   - Private DNS Zone contributor
###########################################################
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.prefix}-msi-aks"
  resource_group_name = azurerm_resource_group.aks.name
  location            = var.location
  tags                = local.tags
}

###########################################################
# PRIVATE DNS ZONE
###########################################################
# We need to pre-create the private DNS zone
# as the DNS resolvers configured on the Virtual Network
# are attached to a different Virtual Network.
###########################################################
# Allow the cluster identity to contribute to the DNS zone.
resource "azurerm_role_assignment" "dns_aks" {
  count = var.cluster_private_dns_zone_id != null ? 1 : 0

  scope                = var.cluster_private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

###########################################################
# NETWORKING
###########################################################
# Cluster will connect to an existing
# Virtual Network and Subnet.
###########################################################
# Allow the principal running terraform to join the subnet
resource "azurerm_role_assignment" "cluster_subnet_network_add_ci" {
  scope                = var.cluster_subnet_id
  role_definition_name = "Network Add"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Allow the cluster identity to join the subnet
resource "azurerm_role_assignment" "cluster_subnet_network_add_aks" {
  scope                = var.cluster_subnet_id
  role_definition_name = "Network Add"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

###########################################################
# AZURE KUBERNETES SERVICE
###########################################################
# Create the Azure Kubernetes Service (AKS) cluster.
#
# We are deploying a private cluster
###########################################################
module "aks" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster.git?ref=v1.0.5"

  prefix                   = var.prefix
  resource_group_name      = azurerm_resource_group.aks.name
  node_resource_group_name = "${azurerm_resource_group.aks.name}-managed"
  location                 = var.location

  kubernetes_version = var.kubernetes_version

  # Assign administrative access
  admin_group_object_ids = var.resource_owners

  # Use a private cluster - this will make a Private Link
  # resource for the control plane and will not
  # make it available from the general internet.
  #
  # Also attach it to our custom private DNS zone
  # so that it is resolvable from the nodes once attached
  # to the cluster virtual network.
  private_cluster_enabled = var.cluster_private_cluster
  private_dns_zone_id     = var.cluster_private_dns_zone_id

  # If not using a private cluster, we need to limit
  # which IPs are authorized to connect to the API server.
  api_server_authorized_ip_ranges = var.cluster_authorized_ip_ranges

  # IP ranges
  docker_bridge_cidr = var.cluster_docker_bridge_cidr
  service_cidr       = var.cluster_service_cidr
  dns_service_ip     = var.cluster_dns_service_ip
  network_policy     = var.network_policy

  # SKU tier for an improved cluster control plane.
  # ("Paid" is preferred)
  sku_tier = var.cluster_sku_tier

  # Use the cluster identity that we created so that it has
  # the appropriate permissions on our resources.
  user_assigned_identity_id = azurerm_user_assigned_identity.aks.id

  # Disk encryption
  # (we also enable host encryption on the node pools below)
  disk_encryption_set_id = azurerm_disk_encryption_set.disk_encryption.id

  # Default node pool (system)
  # We restrict this node pool to running critical components
  # only so that user workloads are unlikely to affect the
  # control plan features of the environment.
  default_node_pool_kubernetes_version   = var.system_node_pool_kubernetes_version
  default_node_pool_subnet_id            = var.cluster_subnet_id
  default_node_pool_critical_addons_only = true
  default_node_pool_vm_size              = var.system_node_pool_vm_size
  # Cannot use BYOK w/ Ephemeral disks
  default_node_pool_disk_type              = "Managed"
  default_node_pool_node_count             = var.system_node_pool_node_count
  default_node_pool_enable_auto_scaling    = var.system_node_pool_enable_auto_scaling
  default_node_pool_auto_scaling_min_nodes = var.system_node_pool_auto_scaling_min_nodes
  default_node_pool_auto_scaling_max_nodes = var.system_node_pool_auto_scaling_max_nodes
  default_node_pool_availability_zones     = var.availability_zones
  default_node_pool_enable_host_encryption = true
  default_node_pool_max_pods               = var.system_node_pool_max_pods

  # CSI Drivers
  storage_profile = var.storage_profile

  # SSH key to connect to the virtual machines
  ssh_key = var.cluster_ssh_key

  # Tags
  tags = local.tags

  depends_on = [
    azurerm_role_assignment.cluster_subnet_network_add_aks,
    azurerm_role_assignment.dns_aks
  ]
}

# Create a storage account for audit logs
resource "azurerm_storage_account" "audit" {
  name                            = replace("${var.prefix}-sa-audit", "-", "")
  location                        = var.location
  resource_group_name             = azurerm_resource_group.aks.name
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  access_tier                     = "Hot"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  tags                            = local.tags

  depends_on = [
    azurerm_role_assignment.aks_rg_owner_ci
  ]
}

resource "azurerm_advanced_threat_protection" "audit" {
  target_resource_id = azurerm_storage_account.audit.id
  enabled            = true
}

resource "azurerm_storage_account_network_rules" "audit" {
  storage_account_id = azurerm_storage_account.audit.id

  default_action             = "Deny"
  virtual_network_subnet_ids = []
  bypass                     = ["Logging", "Metrics", "AzureServices"]
}

# Set audit logs
resource "azurerm_monitor_diagnostic_setting" "kubernetes_audit" {
  name               = "kubernetes-audit"
  target_resource_id = module.aks.kubernetes_cluster_id
  storage_account_id = azurerm_storage_account.audit.id

  log {
    category = "cluster-autoscaler"
    enabled  = false
  }

  log {
    category = "guard"
    enabled  = false
  }

  log {
    category = "kube-apiserver"
    enabled  = false
  }

  log {
    category = "kube-audit"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 60
    }
  }

  log {
    category = "kube-controller-manager"
    enabled  = false
  }

  log {
    category = "kube-scheduler"
    enabled  = false
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}

# General node pool
# Node pool for use by general workloads.
module "nodepool_general" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "general"
  kubernetes_cluster_id = module.aks.kubernetes_cluster_id
  kubernetes_version    = var.general_node_pool_kubernetes_version

  subnet_id = var.cluster_subnet_id
  vm_size   = var.general_node_pool_vm_size
  # Cannot use BYOK w/ Ephemeral disks
  disk_type              = "Managed"
  enable_auto_scaling    = var.general_node_pool_enable_auto_scaling
  node_count             = var.general_node_pool_node_count
  auto_scaling_max_nodes = var.general_node_pool_auto_scaling_max_nodes
  auto_scaling_min_nodes = var.general_node_pool_auto_scaling_min_nodes

  labels = var.general_node_pool_labels
  taints = var.general_node_pool_taints

  availability_zones     = var.availability_zones
  enable_host_encryption = true
  max_pods               = var.general_node_pool_max_pods

  tags = local.tags
}
