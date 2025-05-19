#!/bin/bash
# deploy-hyperv-lab.sh
# This script deploys the Hyper-V Lab to Azure using Azure CLI and the modular Bicep templates

set -e

# Default values
RESOURCE_GROUP="HyperVLab-RG"
LOCATION="eastus"
COMPUTER_NAME="hypervhost"
ADMIN_USERNAME="azureuser"
VM_SIZE="Standard_D8s_v5"
ADMIN_PASSWORD=""

# Help function
function show_help {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -g, --resource-group   Resource group name (default: HyperVLab-RG)"
  echo "  -l, --location         Azure region (default: eastus)"
  echo "  -n, --name             Computer name (default: hypervhost)"
  echo "  -u, --username         Admin username (default: azureuser)"
  echo "  -s, --vm-size          VM size (default: Standard_D8s_v5)"
  echo "  -p, --password         Admin password (required)"
  echo "  -h, --help             Show this help message"
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    -l|--location)
      LOCATION="$2"
      shift 2
      ;;
    -n|--name)
      COMPUTER_NAME="$2"
      shift 2
      ;;
    -u|--username)
      ADMIN_USERNAME="$2"
      shift 2
      ;;
    -s|--vm-size)
      VM_SIZE="$2"
      shift 2
      ;;
    -p|--password)
      ADMIN_PASSWORD="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Check if password is provided
if [[ -z "$ADMIN_PASSWORD" ]]; then
  echo "Error: Admin password is required. Use -p or --password option."
  show_help
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI not found. Please install it before running this script."
  echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

# Check if logged in to Azure
echo "Checking Azure login status..."
ACCOUNT=$(az account show --query name -o tsv 2>/dev/null || echo "")

if [[ -z "$ACCOUNT" ]]; then
  echo "Not logged in to Azure. Please log in..."
  az login
else
  echo "Currently logged in to: $ACCOUNT"
fi

# Create resource group if it doesn't exist
echo "Checking resource group $RESOURCE_GROUP..."
RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")

if [[ "$RG_EXISTS" == "false" ]]; then
  echo "Creating resource group $RESOURCE_GROUP in $LOCATION..."
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
  echo "Resource group $RESOURCE_GROUP already exists."
fi

# Start the deployment
DEPLOYMENT_NAME="HyperVLab-Deployment-$(date +%Y%m%d-%H%M%S)"
echo "Starting deployment $DEPLOYMENT_NAME to resource group $RESOURCE_GROUP..."

# Deploy using Bicep template
az deployment group create \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "./main.bicep" \
  --parameters computerName="$COMPUTER_NAME" \
               AdminUsername="$ADMIN_USERNAME" \
               AdminPassword="$ADMIN_PASSWORD" \
               VirtualMachineSize="$VM_SIZE" \
  --verbose

# Check deployment status
DEPLOYMENT_STATUS=$(az deployment group show \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.provisioningState" \
  -o tsv)

if [[ "$DEPLOYMENT_STATUS" == "Succeeded" ]]; then
  echo -e "\n\033[0;32mDeployment succeeded!\033[0m"
  
  # Get deployment outputs
  HOSTNAME=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.outputs.hostname.value" \
    -o tsv)
  
  RDP_COMMAND=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.outputs.rdpCommand.value" \
    -o tsv)
  
  echo -e "\n\033[0;36mHyper-V Lab Deployment Details:\033[0m"
  echo "================================"
  echo "Computer Name: $COMPUTER_NAME"
  echo "Username: $ADMIN_USERNAME"
  echo "Hostname: $HOSTNAME"
  echo "RDP Command: $RDP_COMMAND"
  echo -e "\nThe deployment takes approximately 30 minutes to complete all VM extensions."
  echo "You can monitor the status in the Azure Portal."
else
  echo -e "\n\033[0;31mDeployment failed with state: $DEPLOYMENT_STATUS\033[0m"
fi
