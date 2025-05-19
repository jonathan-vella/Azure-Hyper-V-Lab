# Test-Deployment.ps1
# This script tests the deployment without creating any resources (what-if mode)

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "HyperVLab-Test-RG",

    [Parameter(Mandatory = $false)]
    [string]$Location = "swedencentral",

    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "hypervhost",

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = "azureuser",

    [Parameter(Mandatory = $false)]
    [string]$VmSize = "Standard_D8s_v5"
)

# Create a secure password for testing purposes only
$securePassword = ConvertTo-SecureString -String "TestPassword123!" -AsPlainText -Force

# Check if Azure PowerShell is installed
if (!(Get-Module -ListAvailable -Name Az)) {
    Write-Error "Azure PowerShell module not found. Please install it by running: Install-Module -Name Az -AllowClobber -Force"
    exit 1
}

# Check Azure connection
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "You are not connected to Azure. Please run Connect-AzAccount to connect."
        Connect-AzAccount
    }
    else {
        Write-Host "Connected to Azure subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
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

# Deploy Bicep template in what-if mode
$deploymentName = "HyperVLab-WhatIf-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Testing deployment '$deploymentName' to resource group '$ResourceGroupName'..." -ForegroundColor Cyan

$parameters = @{
    location = $Location
    computerName = $ComputerName
    AdminUsername = $AdminUsername
    AdminPassword = $securePassword
    VirtualMachineSize = $VmSize
}

# Execute template in what-if mode to show changes without deploying
Write-Host "Running what-if deployment - this will show what would be deployed without creating resources..." -ForegroundColor Yellow
$whatIfResult = Get-AzResourceGroupDeploymentWhatIfResult `
                -ResourceGroupName $ResourceGroupName `
                -TemplateFile "..\..\src\bicep\main.bicep" `
                -TemplateParameterObject $parameters `
                -Name $deploymentName `
                -Verbose

# Display results in a friendly format
Write-Host "`n=== DEPLOYMENT SIMULATION RESULTS ===" -ForegroundColor Cyan

# Count resources by change type
$createCount = ($whatIfResult.Changes | Where-Object { $_.ChangeType -eq 'Create' }).Count
$modifyCount = ($whatIfResult.Changes | Where-Object { $_.ChangeType -eq 'Modify' }).Count
$deleteCount = ($whatIfResult.Changes | Where-Object { $_.ChangeType -eq 'Delete' }).Count
$deployCount = ($whatIfResult.Changes | Where-Object { $_.ChangeType -eq 'Deploy' }).Count
$noChangeCount = ($whatIfResult.Changes | Where-Object { $_.ChangeType -eq 'NoChange' }).Count

# Display summary of changes
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  + Create: $createCount resources" -ForegroundColor Green
Write-Host "  ~ Modify: $modifyCount resources" -ForegroundColor Yellow
Write-Host "  - Delete: $deleteCount resources" -ForegroundColor Red
Write-Host "  > Deploy: $deployCount resources" -ForegroundColor Cyan
Write-Host "  = No Change: $noChangeCount resources" -ForegroundColor Gray

# Display resources that would be created
Write-Host "`nResources that would be created:" -ForegroundColor Green
$whatIfResult.Changes | Where-Object { $_.ChangeType -eq 'Create' } | ForEach-Object {
    Write-Host "  + $($_.ResourceId)" -ForegroundColor Green
}

Write-Host "`nAll changes:" -ForegroundColor Yellow 
$whatIfResult.Changes | ForEach-Object {
    $changeSymbol = switch ($_.ChangeType) {
        'Create' { '+' }
        'Modify' { '~' }
        'Delete' { '-' }
        'Deploy' { '>' }
        'NoChange' { '=' }
        default { '?' }
    }
    
    $color = switch ($_.ChangeType) {
        'Create' { 'Green' }
        'Modify' { 'Yellow' }
        'Delete' { 'Red' }
        'Deploy' { 'Cyan' }
        'NoChange' { 'Gray' }
        default { 'White' }
    }
    
    Write-Host "  $changeSymbol $($_.ResourceId)" -ForegroundColor $color
}

Write-Host "`nTest completed successfully!" -ForegroundColor Cyan
Write-Host "To perform the actual deployment, run: .\src\scripts\Deploy-HyperVLab.ps1"
