# Deploy-HyperVLab.ps1
# This script deploys the Hyper-V Lab to Azure using the modular Bicep templates

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "HyperVLab-RG",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "hypervhost",

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = "azureuser",

    [Parameter(Mandatory = $false)]
    [string]$VmSize = "Standard_D8s_v5",

    [Parameter(Mandatory = $true)]
    [securestring]$AdminPassword
)

# Check if Azure PowerShell is installed and connect to Azure if not connected
if (!(Get-Module -ListAvailable -Name Az)) {
    Write-Error "Azure PowerShell module not found. Please install it by running: Install-Module -Name Az -AllowClobber -Force"
    exit 1
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
    computerName = $ComputerName
    AdminUsername = $AdminUsername
    AdminPassword = $AdminPassword
    VirtualMachineSize = $VmSize
}

# Deploy using Bicep file
$deployment = New-AzResourceGroupDeployment -Name $deploymentName `
                                          -ResourceGroupName $ResourceGroupName `
                                          -TemplateFile ".\main.bicep" `
                                          -TemplateParameterObject $parameters `
                                          -Mode Incremental `
                                          -Verbose

if ($deployment.ProvisioningState -eq "Succeeded") {
    Write-Host "Deployment succeeded!" -ForegroundColor Green
    
    # Get deployment outputs
    $hostname = $deployment.Outputs.hostname.Value
    $rdpCommand = $deployment.Outputs.rdpCommand.Value
    
    Write-Host "`nHyper-V Lab Deployment Details:" -ForegroundColor Cyan
    Write-Host "================================"
    Write-Host "Computer Name: $ComputerName"
    Write-Host "Username: $AdminUsername"
    Write-Host "Hostname: $hostname"
    Write-Host "RDP Command: $rdpCommand"
    Write-Host "`nThe deployment takes approximately 30 minutes to complete all VM extensions."
    Write-Host "You can monitor the status in the Azure Portal."
}
else {
    Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
    Write-Host "Error: $($deployment.Error)" -ForegroundColor Red
}
