locals {
  policy_placeholders = {
    aks_baseline             = "Assign Azure Kubernetes Service baseline policies per environment."
    allowed_locations        = "Restrict Azure regions through policy-as-code."
    required_tags            = "Deny resources missing owner, cost_center, workload, and environment tags."
    private_endpoint_default = "Prefer private endpoints for PaaS dependencies."
  }

  defender_placeholders = {
    containers = "Enable Defender for Containers and connect alerts to the SOC workflow."
    servers    = "Enable Defender for Servers for node-level posture and vulnerability findings."
    key_vault  = "Enable Defender for Key Vault when secrets are onboarded."
  }

  workload_identity_placeholders = {
    key_vault_csi = "Bind Kubernetes service accounts to user-assigned managed identities for Key Vault CSI."
    deployer      = "Use federated credentials for CI/CD deployments instead of long-lived secrets."
  }
}
