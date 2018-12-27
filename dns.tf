# This file defines the DNS entries for the neudesicgcp.com domain.

# Create a DNS zone
resource "google_dns_managed_zone" "root" {
  name        = "neudesicgcp-root"
  project     = "${module.neudesicgcp.project_id}"
  dns_name    = "neudesicgcp.com."
  description = "Root DNS zone for neudesicgcp.com"
}

# Enable DNSSEC - this can't be done through Terraform yet so use a couple of
# scripts to enable DNSSEC and retrieve the key to add to registrar
resource "null_resource" "enable_dnssec" {
  triggers = {
    root_zone = "${google_dns_managed_zone.root.name}"
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/enable_dnssec.sh ${module.neudesicgcp.project_id} ${google_dns_managed_zone.root.name} ${local.terraform_creds}"
  }

  depends_on = ["google_dns_managed_zone.root"]
}

data "external" "dnssec_key" {
  program = [
    "${path.module}/scripts/get_dnssec_key.sh",
    "${module.neudesicgcp.project_id}",
    "${google_dns_managed_zone.root.name}",
    "${local.terraform_creds}",
  ]

  depends_on = ["null_resource.enable_dnssec"]
}

# Github verified domain entry
resource "google_dns_record_set" "github_verififcation" {
  name         = "_github-challenge-NeudesicGCP.${google_dns_managed_zone.root.dns_name}"
  project      = "${module.neudesicgcp.project_id}"
  type         = "TXT"
  ttl          = "3600"
  managed_zone = "${google_dns_managed_zone.root.name}"
  rrdatas      = ["e83e004e30"]
}
