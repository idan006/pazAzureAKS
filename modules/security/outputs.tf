output "policy_placeholders" {
  description = "Azure Policy controls to implement during hardening."
  value       = local.policy_placeholders
}

output "defender_placeholders" {
  description = "Defender for Cloud controls to implement during hardening."
  value       = local.defender_placeholders
}

output "workload_identity_placeholders" {
  description = "Workload identity controls to implement during hardening."
  value       = local.workload_identity_placeholders
}
