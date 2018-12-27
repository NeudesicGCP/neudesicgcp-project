# Export the project id
output "project_id" {
  value = "${module.neudesicgcp.project_id}"
}

# Export the DNS servers to add to domain registrar records
output "nameservers" {
  value = "${google_dns_managed_zone.root.name_servers}"
}

# DNSSEC settings
output "dnssec_key" {
  value = "${data.external.dnssec_key.result}"
}
