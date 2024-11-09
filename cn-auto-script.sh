#!/bin/bash

# Define regions
regions=(
    "chinanorth3"
    "chinanorth2"
    "chinanorth"
    "chinaeast3"
    "chinaeast2"
    "chinaeast"
)

# Output directory
output_dir="/home/roccoren/azcharts"

# Storage details
storage_account="azchartscn"
container_name="china"

# Power Automate webhook URL
power_automate_url="https://prod-27.westus3.logic.azure.com:443/workflows/96e9b10466814fcc8b470df3074dafda/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=Bbo63W4xXQejQM93bxE7kHyQBKjen-StH1uCajtqcIY"

# Generate SAS token valid for 169 hours
expiry=$(date -u -d "169 hours" '+%Y-%m-%dT%H:%MZ')
sas_token=$(az storage container generate-sas \
    --account-name "$storage_account" \
    --name "$container_name" \
    --permissions rwdlac \
    --expiry "$expiry" \
    --https-only \
    --output tsv)

# Authenticate using managed identity
az login --identity

# Send SAS token to Power Automate
curl -X POST "$power_automate_url" \
    -H "Content-Type: application/json" \
    -d "{\"sas_token\":\"$sas_token\"}"

for region in "${regions[@]}"; do
    file_name="${output_dir}/${region}.json"
    az vm list-skus --resource-type virtualMachines --location "$region" > "$file_name"
    az storage blob upload --account-name "$storage_account" --container-name "$container_name" --name "${region}.json" --file "$file_name" --auth-mode login --overwrite
done
