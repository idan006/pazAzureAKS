output "id" {
  description = "AKS cluster ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "private_fqdn" {
  description = "Private AKS API FQDN."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "principal_id" {
  description = "AKS control plane managed identity principal ID."
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "kubelet_identity" {
  description = "AKS kubelet identity."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}
