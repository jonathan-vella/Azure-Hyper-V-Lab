# Deploy-HyperVLab.ps1
# This script deploys the Hyper-V Lab to Azure using the modular Bicep templates

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "HyperVLab-RG",

    [Parameter(Mandatory = $false)]
    [string]$Location = "swedencentral",    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "hypervhost",

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = "demouser",

    [Parameter(Mandatory = $false)]
    [string]$VmSize = "Standard_D8s_v5",

    [Parameter(Mandatory = $true)]
    [securestring]$AdminPassword,

    [Parameter(Mandatory = $false)]
    [bool]$DeployBastion = $true,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Standard")]
    [string]$BastionSku = "Basic"
)

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# Check if Azure PowerShell is installed
if (!(Get-Module -ListAvailable -Name Az)) {
    Write-Error "Azure PowerShell module not found. Please install it by running: Install-Module -Name Az -AllowClobber -Force"
    exit 1
}

# Check if Bicep CLI is installed
try {
    $bicepVersion = bicep --version
    Write-Host "Bicep CLI version: $bicepVersion" -ForegroundColor Green
} catch {
    Write-Warning "Bicep CLI not found. This is not critical as Azure PowerShell can deploy Bicep files, but the Bicep CLI is recommended for local development."
    Write-Host "To install Bicep CLI, see: https://learn.microsoft.com/azure/azure-resource-manager/bicep/install" -ForegroundColor Yellow
}

try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "You are not connected to Azure. Please run Connect-AzAccount to connect."
        Connect-AzAccount
    }
    else {
        Write-Host "Connected to Azure subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
    }
}
catch {
    Write-Host "You are not connected to Azure. Please run Connect-AzAccount to connect."
    Connect-AzAccount
}

# Create resource group if it doesn't exist
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group '$ResourceGroupName' in location '$Location'"
    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
else {
    Write-Host "Using existing resource group '$ResourceGroupName'"
}

# Deploy Bicep template
$deploymentName = "HyperVLab-Deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Starting deployment '$deploymentName' to resource group '$ResourceGroupName'..."

$parameters = @{
    location = $Location
    computerName = $ComputerName
    AdminUsername = $AdminUsername
    AdminPassword = $AdminPassword
    VirtualMachineSize = $VmSize
    deployBastion = $DeployBastion
    bastionSku = $BastionSku
}

# Deploy using Bicep file
$deployment = New-AzResourceGroupDeployment -Name $deploymentName `
                                          -ResourceGroupName $ResourceGroupName `
                                          -TemplateFile "..\..\src\bicep\main.bicep" `
                                          -TemplateParameterObject $parameters `
                                          -Mode Incremental `
                                          -Verbose

if ($deployment.ProvisioningState -eq "Succeeded") {
    Write-Host "Deployment succeeded!" -ForegroundColor Green
      # Get deployment outputs
    $vmName = $deployment.Outputs.vmName.Value
    $bastionEnabled = $deployment.Outputs.bastionEnabled.Value
    $bastionName = $deployment.Outputs.bastionName.Value
    $vmPrivateIp = $deployment.Outputs.vmPrivateIp.Value
    $connectionMethod = $deployment.Outputs.connectionMethod.Value
    
    Write-Host "`nHyper-V Lab Deployment Details:" -ForegroundColor Cyan
    Write-Host "================================"
    Write-Host "VM Name: $vmName"
    Write-Host "VM Private IP: $vmPrivateIp"
    Write-Host "Username: $AdminUsername"
    Write-Host "Bastion Enabled: $bastionEnabled"
    Write-Host "Bastion Name: $bastionName"
    Write-Host "Connection Method: $connectionMethod"
    Write-Host "`nThe deployment takes approximately 30 minutes to complete all VM extensions."
    Write-Host "You can monitor the status in the Azure Portal."
}
else {
    Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
    Write-Host "Error: $($deployment.Error)" -ForegroundColor Red
}
