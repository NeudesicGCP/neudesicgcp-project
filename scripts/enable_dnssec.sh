#!/bin/sh
#
# Enables DNSSEC on the managed zone
#
# $1 = project id, required
# $2 = managed zone name, required
# $3 = credentials file to use, optional

set -e

error()
{
    echo "$0: Error: $*" >&2
    exit 1
}

# Sanity checks
[ -z "${1}" ] && error "PROJECT_ID must be provided as first argument"
[ -z "${2}" ] && error "MANAGED_ZONE name must be provided as second argument"

# On exit reset the gcloud auth account to prior value
CURRENT_AUTH=$(gcloud config get-value account)
trap reset_auth 0 1 2 3 6
reset_auth()
{
    gcloud config set account "${CURRENT_AUTH}"
}

# If credentials file exists, switch to that account
[ -n "${3}" ] && [ -r "${3}" ] && \
    gcloud auth activate-service-account --key-file="${3}"

# Enable DNSSEC for the managed zone
gcloud dns managed-zones update "${2}" \
       --project="${1}" \
       --dnssec-state=on
