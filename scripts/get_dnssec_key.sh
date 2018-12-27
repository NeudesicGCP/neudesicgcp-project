#!/bin/sh
#
# Retrieves the active DNSSEC key to set in registrar
# $1 = project id, required
# $2 = managed zone name, required
# $3 = credentials file to use, optional

set -e

error()
{
    echo "$0: Error: $*" >&2
    exit 1
}

# Extract settings from input JSON
command -v jq >/dev/null || error "jq executable must be on the path"

# Sanity checks
[ -z "${1}" ] && error "PROJECT_ID must be specified as option 1"
[ -z "${2}" ] && error "MANAGED_ZONE name must be specified as option 2"

# On exit reset the gcloud auth account to prior value
CURRENT_AUTH=$(gcloud config get-value account)
trap reset_auth 0 1 2 3 6
reset_auth()
{
    gcloud config set account "${CURRENT_AUTH}" > /dev/null 2>/dev/null
}

# If credentials file exists, switch to that account
[ -n "${3}" ] && [ -r "${3}" ] && \
    gcloud auth activate-service-account \
           --key-file="${3}" > /dev/null 2>/dev/null

# Get the DNSSEC key
KEY_ID=$(gcloud dns dns-keys list \
                --project="${1}" \
                --zone="${2}" \
                --filter='type:keySigning AND isActive:true' \
                --format='value(ID)')
[ -z "${KEY_ID}" ] && error "DNSSEC signing key was not found"

# Return the relevant portion of the keys for use in registrar
# Note: Terraform expects a map of string:string, so convert keyTag to string
# and flatten the digests.
gcloud dns dns-keys describe ${KEY_ID} \
       --project="${1}" \
       --zone="${2}" \
       --format='json(algorithm,digests[0],keyTag)' | \
    jq '{ algorithm: .algorithm, keyTag: .keyTag|tostring, digest: .digests[0].digest, digestType: .digests[0].type}'
