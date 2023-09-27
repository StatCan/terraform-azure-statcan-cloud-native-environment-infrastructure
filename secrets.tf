###########################################################
# SECRETS RESOURCE GROUP
###########################################################
# Resource group to store secrets-related resource.
###########################################################
resource "azurerm_resource_group" "secrets" {
  name     = "${var.prefix}-rg-secrets"
  location = var.location
  tags     = var.tags

  lifecycle {
    ignore_changes = [tags.DateCreatedModified]
  }
}

# The principal running the terraform needs to be
# an "Owner" on the resource group in order
# to deploy resources and assign permission.
resource "azurerm_role_assignment" "secrets_rg_owner_ci" {
  scope                = azurerm_resource_group.secrets.id
  role_definition_name = "Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign reader permissions to the principals
# defined in the `resource_owners` variable.
# This is typically an Azure AD group contain
# administrative users.
#
# We do not grant Owner since administrators
# would then be able to grant themselves
# permissions to the KeyVault.
resource "azurerm_role_assignment" "secrets_rg_reader_resource_owners" {
  for_each = toset(var.resource_owners)

  scope                = azurerm_resource_group.secrets.id
  role_definition_name = "Reader"
  principal_id         = each.value
}

###########################################################
# DISK ENCRYPTION
###########################################################
# Setup disk encryption resources using
# customer managed keys backed by an HSM key.
###########################################################
resource "azurerm_key_vault" "keys" {
  name                        = "${var.prefix}-kv-enc"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.secrets.name
  tags                        = var.tags
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = var.infrastructure_pipeline_subnet_ids
    ip_rules                   = var.infrastructure_pipeline_allowed_ip_ranges
  }

  depends_on = [
    azurerm_role_assignment.secrets_rg_owner_ci
  ]
}

# Allow the runner to managed key vault keys
resource "azurerm_key_vault_access_policy" "ci_keys" {
  key_vault_id = azurerm_key_vault.keys.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "Create",
    "Delete"
  ]
}

# Create a key for disk encryption
resource "azurerm_key_vault_key" "disk_encryption" {
  depends_on = [
    azurerm_key_vault_access_policy.ci_keys
  ]

  name         = "${var.prefix}-key-disk-encryption"
  key_vault_id = azurerm_key_vault.keys.id

  # Use an HSM-backed key
  key_type = "RSA-HSM"

  # Key size of 3072 is recommended by 2030, 4096 is largest supported
  # https://cyber.gc.ca/en/guidance/cryptographic-algorithms-unclassified-protected-and-protected-b-information-itsp40111
  key_size = "4096"

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

# Create a disk encryption set
resource "azurerm_disk_encryption_set" "disk_encryption" {
  name                = "${var.prefix}-des"
  resource_group_name = azurerm_resource_group.secrets.name
  location            = var.location
  tags                = var.tags
  key_vault_key_id    = azurerm_key_vault_key.disk_encryption.id

  identity {
    type = "SystemAssigned"
  }
}

# Allow the disk encryption set to access to the Key Vault key
resource "azurerm_key_vault_access_policy" "des_keys" {
  key_vault_id = azurerm_key_vault.keys.id

  tenant_id = azurerm_disk_encryption_set.disk_encryption.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.disk_encryption.identity.0.principal_id

  key_permissions = [
    "Get",
    "GetRotationPolicy",
    "UnwrapKey",
    "WrapKey",
  ]
}

# Allow the cluster identity to join the subnet
resource "azurerm_role_assignment" "cluster_read_des" {
  scope                = azurerm_disk_encryption_set.disk_encryption.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
