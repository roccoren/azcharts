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
output_dir="."

# Storage details
storage_account="azchartscn"
container_name="china"

# Log file
log_file="${output_dir}/upload.log"

# Authenticate using managed identity
if ! az login --identity; then
    echo "Failed to authenticate using managed identity" | tee -a "$log_file"
    exit 1
fi

# Function to process each region
process_region() {
    local region=$1
    local file_name="${output_dir}/${region}.json"
    
    if ! az vm list-skus --resource-type virtualMachines --location "$region" > "$file_name"; then
        echo "Failed to list SKUs for region $region" | tee -a "$log_file"
        return 1
    fi
    
    if ! az storage blob upload --account-name "$storage_account" --container-name "$container_name" --name "${region}.json" --file "$file_name" --auth-mode login --overwrite; then
        echo "Failed to upload blob for region $region" | tee -a "$log_file"
        return 1
    fi
    
    echo "Successfully processed region $region" | tee -a "$log_file"
}

# Export the function and variables for parallel execution
export -f process_region
export output_dir storage_account container_name log_file

# Process regions in parallel
echo "Starting processing of regions..." | tee -a "$log_file"
parallel process_region ::: "${regions[@]}"

echo "All regions processed." | tee -a "$log_file"
