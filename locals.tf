locals {
  tags = merge(var.tags, { ModuleName = "terraform-azure-statcan-cloud-native-environment-infrastructure" }, { ModuleVersion = "1.0.4" })
}
