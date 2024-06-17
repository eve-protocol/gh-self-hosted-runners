resource "azurerm_container_app_environment" "main" {
  location                           = azurerm_resource_group.main.location
  name                               = "${local.resource_prefix}-aca-env"
  resource_group_name                = azurerm_resource_group.main.name
  infrastructure_resource_group_name = "${local.resource_prefix}-aca-rg"
  infrastructure_subnet_id           = azurerm_subnet.aca.id
  internal_load_balancer_enabled     = true
  log_analytics_workspace_id         = azurerm_log_analytics_workspace.main.id
  workload_profile {
    workload_profile_type = "Consumption"
    name                  = "Consumption"
  }
}

resource "azurerm_user_assigned_identity" "main" {
  location            = azurerm_resource_group.main.location
  name                = "${local.resource_prefix}-aca-identity"
  resource_group_name = azurerm_resource_group.main.name

}

resource "azurerm_role_assignment" "key_vault" {
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"

}

resource "azurerm_role_assignment" "current" {
  principal_id         = data.azuread_client_config.current.object_id
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"

}

resource "azurerm_role_assignment" "acr" {
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = var.acr_resource_id
  role_definition_name = "AcrPull"

}

resource "random_string" "keyvault" {
  length  = 5
  special = false
}

resource "azurerm_key_vault" "main" {
  location                  = azurerm_resource_group.main.location
  name                      = "${replace(local.resource_prefix, "-", "")}${random_string.keyvault.result}"
  resource_group_name       = azurerm_resource_group.main.name
  sku_name                  = "standard"
  tenant_id                 = data.azuread_client_config.current.tenant_id
  enable_rbac_authorization = true
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = ["${chomp(data.http.myip.response_body)}/32"]
    virtual_network_subnet_ids = [azurerm_subnet.aca.id]
  }

}

resource "azurerm_key_vault_secret" "main" {
  key_vault_id = azurerm_key_vault.main.id
  name         = local.secret_name
  value        = var.github_app_key

  depends_on = [azurerm_role_assignment.current]

}

resource "azurerm_container_app_job" "main" {
  container_app_environment_id = azurerm_container_app_environment.main.id
  location                     = azurerm_resource_group.main.location
  name                         = "${local.resource_prefix}-aca-job"
  replica_timeout_in_seconds   = 1800

  resource_group_name = azurerm_resource_group.main.name

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }
  event_trigger_config {
    scale {
      rules {
        custom_rule_type = "github-runner"
        name             = "github-runner-scaling-rule"
        authentication {
          trigger_parameter = "appKey"
          secret_name       = local.secret_name
        }
        metadata = {
          owner          = var.github_organization
          runnerScope    = "org"
          applicationID  = var.github_app_id
          installationID = var.github_app_installation_id
          labels         = "container-apps"
        }
      }
    }
  }
  secret {
    identity            = azurerm_user_assigned_identity.main.id
    key_vault_secret_id = azurerm_key_vault_secret.main.id
    name                = local.secret_name
    value               = ""
  }
  registry {
    server   = var.container_registry_server
    identity = azurerm_user_assigned_identity.main.id
  }
  template {
    container {
      cpu    = "0.25"
      image  = "${var.container_registry_server}/${var.github_organization}/sre-github-runner:dd730bf"
      memory = "0.5Gi"
      name   = "sre-github-runner"
      env {
        name  = "APP_ID"
        value = var.github_app_id
      }
      env {
        name  = "APP_INSTALLATION_ID"
        value = var.github_app_installation_id
      }
      env {
        name  = "RUNNER_SCOPE"
        value = "org"
      }
      env {
        name  = "GH_OWNER"
        value = var.github_organization
      }
      env {
        name  = "APPSETTING_WEBSITE_SITE_NAME"
        value = "az-cli-workaround"
      }
      env {
        name  = "MSI_CLIENT_ID"
        value = azurerm_user_assigned_identity.main.client_id
      }
      env {
        name  = "EPHEMERAL"
        value = "1"
      }
      env {
        name  = "RUNNER_NAME_PREFIX"
        value = "gh-aca"
      }
      env {
        name        = "APP_PRIVATE_KEY"
        secret_name = local.secret_name
      }
    }
  }

  lifecycle {
    ignore_changes = [secret]
  }

}
