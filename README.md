# Statistics Canada: Azure Cloud Native Environment Infrastructure

## Introduction

This module deploys the Azure infrastructure required for a
Cloud Native Environment within the Statistics Canada
Azure Enterprise cloud environment.

## Security Controls

This module meets the ITSG-33 controls required by Statistics Canada
for the deployment of Kubernetes infrastructure in order to operate
a Kubernetes cluster at PBMM, including inheriting from the
Azure Fundamentals security assessment.

## Dependencies

* An Azure subscription
* An Azure account with sufficient privileges to deploy:
  * Resource group
  * Role assignment

### Networking

Nodes in the cluster must be attached to an existing subnet within an Azure Virtual Network.
The subnet **must** have a Network Virtual Appliance at the default route (ie. `0.0.0.0/0`). See the [Azure documentation on egress](https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype#outbound-type-of-userdefinedrouting) for more information. This can be an Azure Firewall or a virtual appliance performing firewall/routing functions.

Ensure your virtual network IP space does not overlap with the subnets defined in the [Azure CNI prerequisites](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#prerequisites).

## Optional (depending on options configured):

* None

## Usage

```terraform
module "infrastructure" {
  source = "git::https://github.com/statcan/terraform-statcan-azure-cloud-native-environment-infrastructure.git?ref=$REF"

  # ... your variable values
}
```

## Variables Values

| Name                                      | Type         | Required | Value                                                                          |
| ----------------------------------------- | ------------ | -------- | ------------------------------------------------------------------------------ |
| prefix                                    | string       | yes      | Prefix for Azure resources created by the module                               |
| location                                  | string       | yes      | Azure region where to deploy the Azure resources                               |
| tags                                      | map(string)  | no       | Azure tags assigned to Azure resources                                         |
| resource_owners                           | list(string) | no       | List of Principal IDs which will have "Owner" permissions on resources         |
| infrastructure_pipeline_subnet_ids        | list(string) | no       | Subnet ID(s) of instrastructure pipeline                                       |
| infrastructure_pipeline_allowed_ip_ranges | list(string) | no       | Additional allowed IP ranges for infrastructure pipelines                      |
| cluster_private_cluster                   | bool         | no       | Deploy a cluster with a private control plane                                  |
| cluster_private_dns_zone_id               | string       | yes      | ID of the Private DNS zone to be used by the cluster                           |
| cluster_subnet_id                         | string       | yes      | Subnet to attach cluster nodes to                                              |
| cluster_docker_bridge_cidr                | string       | no       | IP range used by the docker bridge                                             |
| cluster_dns_service_ip                    | string       | no       | IP assigned to the cluster DNS service                                         |
| cluster_sku_tier                          | string       | no       | SKU Tier of Kubernetes cluster ("Paid" is preferred)                           |
| cluster_authorized_ip_ranges              | list(string) | no       | Authorized IP ranges for connecting to the cluster control plane               |
| cluster_ssh_key                           | string       | yes      | SSH public key to access cluster nodes                                         |
| availability_zones                        | list(string) | no       | List of availability zones used by the cluster                                 |
| system_node_pool_kubernetes_version       | string       | no       | Kubernetes version for the system node pool                                    |
| system_node_pool_vm_size                  | string       | no       | VM size used by the system node pool                                           |
| system_node_pool_node_count               | number       | no       | Number of nodes in the system node pool                                        |
| system_node_pool_enable_auto_scaling      | bool         | no       | Enable auto scaling of the system node pool                                    |
| system_node_pool_auto_scaling_min_nodes   | number       | no       | Minimum number of nodes in the system node pool, when auto scaling is enabled  |
| system_node_pool_auto_scaling_max_nodes   | number       | no       | Maximum number of nodes in the system node pool, when auto scaling is enabled  |
| system_node_pool_max_pods                 | number       | no       | Maximum number of pods per node in the system node pool                        |
| general_node_pool_vm_size                 | string       | no       | VM size used by the system node pool                                           |
| general_node_pool_node_count              | number       | no       | Number of nodes in the system node pool                                        |
| general_node_pool_enable_auto_scaling     | bool         | no       | Enable auto scaling of the general node pool                                   |
| general_node_pool_auto_scaling_min_nodes  | number       | no       | Minimum number of nodes in the general node pool, when auto scaling is enabled |
| general_node_pool_auto_scaling_max_nodes  | number       | no       | Maximum number of nodes in the general node pool, when auto scaling is enabled |
| general_node_pool_max_pods                | number       | no       | Maximum number of pods per node in the general node pool                       |
| general_node_pool_labels                  | map(string)  | no       | Labels applied to the nodes in the general node pool                           |
| general_node_pool_taints                  | list(string) | no       | Taints applied to nodes in the general node pool                               |
| network_policy                            | string       | no       | Network policy provider (auzre or calico)                                      |
| kuberenetes_version                       | string       | no       | Version of Kubernetes to use                                                   |
| cluster_users                             | list(string) | no       | List of users/groups who can pull the kubeconfig                               |
| cluster_admins                            | list(string) | no       | List of users/groups who can pull the admin kubeconfig                         |

## History

| Date       | Release | Change                                         |
| ---------- | ------- | ---------------------------------------------- |
| 2021-07-06 | 1.0.0   | Initial release                                |
| 2023-02-02 | 1.0.1   | Specify sensitive variables                    |
| 2023-07-31 | 1.0.2   | Leverage AKS managed blob-csi driver           |
| 2023-07-31 | 1.0.3   | Fix load_balancer_sku case                     |
| 2023-09-13 | 1.0.4   | Implement tagging strategy for Azure resources |
