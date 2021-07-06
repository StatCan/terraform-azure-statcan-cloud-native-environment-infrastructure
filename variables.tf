variable "prefix" {
  description = "Prefix for Azure resources"
}

variable "location" {
  description = "Azure region to deploy Azure resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags attached to Azure resource"

  default = {}
}

variable "resource_owners" {
  type        = list(string)
  description = "List of principal IDs (either Users, Groups or ServiceAccounts) which will have \"Owner\" permissions on the resource group"

  default = []
}

### Networking
variable "cluster_private_cluster" {
  type        = bool
  description = "Deploy a cluster with a private control plane"
  default     = true
}

variable "cluster_private_dns_zone_id" {
  description = "Private DNS Zone ID for the cluster"

  default = null
}

variable "cluster_subnet_id" {
  description = "Subnet ID to join cluster nodes"
}

variable "cluster_docker_bridge_cidr" {
  description = "IP range to be used by the docker bridge"

  default = "172.17.0.1/16"
}

variable "cluster_service_cidr" {
  description = "IP range to be used by the docker bridge"

  default = "10.0.0.0/16"
}

variable "cluster_dns_service_ip" {
  description = "IP assigned to the cluster DNS service"

  default = "10.0.0.10"
}

variable "infrastructure_pipeline_subnet_ids" {
  type        = list(string)
  description = "Subnet ID of infrastructure pipeline"

  default = []
}

variable "infrastructure_pipeline_allowed_ip_ranges" {
  type        = list(string)
  description = "Additional allowed IP ranges for infrastructure pipelines"

  default = []
}

### Cluster
variable "cluster_sku_tier" {
  description = "SKU Tier for the cluster (\"Paid\" is preferred)"

  default = "Paid"
}

variable "cluster_authorized_ip_ranges" {
  type        = list(string)
  description = "Authorized IP ranges for connecting to the cluster control plane"

  default = null
}

variable "cluster_ssh_key" {
  description = "SSH public key to access cluster nodes"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones used by the cluster"

  default = []
}

### SYSTEM NODE POOL
variable "system_node_pool_kubernetes_version" {
  description = "Kubernetes version for the system node pool"

  default = null
}

variable "system_node_pool_vm_size" {
  description = "VM size used by the system node pool"

  default = "Standard_D16s_v3"
}

variable "system_node_pool_node_count" {
  description = "Number of nodes in the system node pool"

  default = 3
}

variable "system_node_pool_enable_auto_scaling" {
  type        = bool
  description = "Enable auto scaling of the system node pool"

  default = false
}

variable "system_node_pool_auto_scaling_min_nodes" {
  type        = number
  description = "Minimum number of nodes in the system node pool, when auto scaling is enabled"

  default = 3
}

variable "system_node_pool_auto_scaling_max_nodes" {
  type        = number
  description = "Maximum number of nodes in the system node pool, when auto scaling is enabled"

  default = 5
}

variable "system_node_pool_max_pods" {
  description = "Maximum number of pods per node in the system node pool"

  default = 60
}

### GENERAL NODE POOL
variable "general_node_pool_kubernetes_version" {
  description = "Kubernetes version for the general node pool"

  default = null
}

variable "general_node_pool_vm_size" {
  description = "VM size used by the general node pool"

  default = "Standard_D16s_v3"
}

variable "general_node_pool_node_count" {
  description = "Number of nodes in the general node pool"

  default = 3
}

variable "general_node_pool_enable_auto_scaling" {
  type        = bool
  description = "Enable auto scaling of the general node pool"

  default = false
}

variable "general_node_pool_auto_scaling_min_nodes" {
  type        = number
  description = "Minimum number of nodes in the general node pool, when auto scaling is enabled"

  default = 0
}

variable "general_node_pool_auto_scaling_max_nodes" {
  type        = number
  description = " Maximum number of nodes in the general node pool, when auto scaling is enabled"

  default = 3
}

variable "general_node_pool_labels" {
  type        = map(string)
  description = "Labels applied to the nodes in the general node pool "

  default = {}
}

variable "general_node_pool_taints" {
  type        = list(string)
  description = "Taints applied to nodes in the general node pool"

  default = []
}

variable "general_node_pool_max_pods" {
  description = "Maximum number of pods per node in the general node pool"

  default = 60
}

variable "network_policy" {
  description = "Network policy provider to use"

  default = "azure"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
}

# RBAC
variable "cluster_users" {
  type        = list(string)
  description = "List of users/groups who can pull the kubeconfig"

  default = []
}

variable "cluster_admins" {
  type        = list(string)
  description = "List of users/groups who can pull the admin kubeconfig"

  default = []
}
