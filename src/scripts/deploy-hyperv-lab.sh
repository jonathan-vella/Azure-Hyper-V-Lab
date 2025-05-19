#!/bin/bash
# deploy-hyperv-lab.sh
# This script deploys the Hyper-V Lab to Azure using Azure CLI and the modular Bicep templates

set -e

# Default values
RESOURCE_GROUP="HyperVLab-RG"
LOCATION="swedencentral"
COMPUTER_NAME="hypervhost"
ADMIN_USERNAME="demouser"
VM_SIZE="Standard_D8s_v5"
ADMIN_PASSWORD=""
DEPLOY_BASTION=true
BASTION_SKU="Basic"

# Help function
function show_help {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -g, --resource-group   Resource group name (default: HyperVLab-RG)"
  echo "  -l, --location         Azure region (default: swedencentral)"
  echo "  -n, --name             Computer name (default: hypervhost)"
  echo "  -u, --username         Admin username (default: demouser)"
  echo "  -s, --vm-size          VM size (default: Standard_D8s_v5)"
  echo "  -p, --password         Admin password (required)"
  echo "  -b, --bastion          Deploy Azure Bastion (true/false, default: true)"
  echo "  -k, --bastion-sku      Azure Bastion SKU (Basic/Standard, default: Basic)"
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
    -b|--bastion)
      DEPLOY_BASTION="$2"
      shift 2
      ;;
    -k|--bastion-sku)
      BASTION_SKU="$2"
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

# Check prerequisites
echo -e "\033[0;36mChecking prerequisites...\033[0m"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
  echo -e "\033[0;31mError: Azure CLI not found. Please install it before running this script.\033[0m"
  echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
else
  AZ_VERSION=$(az version --query '"azure-cli"' -o tsv)
  echo -e "\033[0;32mAzure CLI version $AZ_VERSION is installed\033[0m"
fi

# Check if Bicep CLI is installed
if ! command -v bicep &> /dev/null; then
  echo -e "\033[0;33mWarning: Bicep CLI not found. This is not critical as Azure CLI can deploy Bicep files, but the Bicep CLI is recommended for local development.\033[0m"
  echo "To install Bicep CLI, see: https://learn.microsoft.com/azure/azure-resource-manager/bicep/install"
else
  BICEP_VERSION=$(bicep --version)
  echo -e "\033[0;32mBicep CLI version $BICEP_VERSION is installed\033[0m"
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
  --template-file "../../src/bicep/main.bicep" \
  --parameters location="$LOCATION" \
               computerName="$COMPUTER_NAME" \
               AdminUsername="$ADMIN_USERNAME" \
               AdminPassword="$ADMIN_PASSWORD" \
               VirtualMachineSize="$VM_SIZE" \
               deployBastion="$DEPLOY_BASTION" \
               bastionSku="$BASTION_SKU" \
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
  VM_NAME=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.outputs.vmName.value" \
    -o tsv)
  
  VM_PRIVATE_IP=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.outputs.vmPrivateIp.value" \
    -o tsv)
  
  BASTION_ENABLED=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.outputs.bastionEnabled.value" \
    -o tsv)
    
  BASTION_NAME=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.outputs.bastionName.value" \
    -o tsv)
    
  CONNECTION_METHOD=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.outputs.connectionMethod.value" \
    -o tsv)
  
  echo -e "\n\033[0;36mHyper-V Lab Deployment Details:\033[0m"
  echo "================================"
  echo "VM Name: $VM_NAME"
  echo "VM Private IP: $VM_PRIVATE_IP"
  echo "Username: $ADMIN_USERNAME"
  echo "Bastion Enabled: $BASTION_ENABLED"
  echo "Bastion Name: $BASTION_NAME"
  echo "Connection Method: $CONNECTION_METHOD"
  echo -e "\nThe deployment takes approximately 30 minutes to complete all VM extensions."
  echo "You can monitor the status in the Azure Portal."
else
  echo -e "\n\033[0;31mDeployment failed with state: $DEPLOYMENT_STATUS\033[0m"
fi
