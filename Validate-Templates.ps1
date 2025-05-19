# Validate-Templates.ps1
# Script to validate all Bicep templates before deployment

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus"
)

# Variables
$resourceGroupName = "HyperVLab-Validation-RG"
$validationDate = Get-Date -Format "yyyyMMdd-HHmmss"
$bicepFiles = @(
    ".\main.bicep",
    ".\modules\network.bicep",
    ".\modules\vm.bicep",
    ".\modules\vm-extensions.bicep"
)

Write-Host "Starting validation of Bicep templates..." -ForegroundColor Cyan

# Check for Azure PowerShell module
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
        Write-Host "Connected to Azure subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
    }
}
catch {
    Write-Host "You are not connected to Azure. Please run Connect-AzAccount to connect."
    Connect-AzAccount
}

# Create a temporary resource group for validation if it doesn't exist
$rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Creating temporary resource group '$resourceGroupName' for validation..." -ForegroundColor Yellow
    $rg = New-AzResourceGroup -Name $resourceGroupName -Location $Location
}

# Test parameters for validation
$parameters = @{
    computerName = "validationvm"
    AdminUsername = "validationuser"
    AdminPassword = (ConvertTo-SecureString -String "Validation123!" -AsPlainText -Force)
    VirtualMachineSize = "Standard_D8s_v5"
}

# Validate each Bicep file
$errors = $false

foreach ($bicepFile in $bicepFiles) {
    $fileName = Split-Path -Path $bicepFile -Leaf
    Write-Host "`nValidating $fileName..." -ForegroundColor Yellow
    
    try {
        # Use Bicep CLI to validate syntax
        Write-Host "Checking syntax with Bicep CLI..."
        $bicepResult = bicep build $bicepFile 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Bicep syntax validation failed for $fileName" -ForegroundColor Red
            Write-Host $bicepResult -ForegroundColor Red
            $errors = $true
            continue
        }
        
        Write-Host "✅ Bicep syntax validation passed for $fileName" -ForegroundColor Green
        
        # For main.bicep, validate against Azure using what-if
        if ($fileName -eq "main.bicep") {
            Write-Host "Validating deployment with Azure (what-if)..."
            $result = Get-AzResourceGroupDeploymentWhatIfResult `
                -ResourceGroupName $resourceGroupName `
                -TemplateFile $bicepFile `
                -TemplateParameterObject $parameters `
                -Name "validation-$validationDate" `
                -SkipTemplateParameterPrompt `
                -ErrorAction Stop
                
            Write-Host "✅ Azure validation passed for $fileName" -ForegroundColor Green
            
            # Display changes that would be made
            Write-Host "`nResources that would be deployed:" -ForegroundColor Cyan
            $result.Changes | ForEach-Object {
                Write-Host "- $($_.ResourceId)" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "❌ Validation failed for $fileName" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        $errors = $true
    }
}

# Summary
Write-Host "`n====== VALIDATION SUMMARY ======" -ForegroundColor Cyan
if ($errors) {
    Write-Host "❌ Validation failed! Please fix the errors before deployment." -ForegroundColor Red
}
else {
    Write-Host "✅ All templates validated successfully!" -ForegroundColor Green
}

Write-Host "`nNote: The temporary resource group '$resourceGroupName' was created for validation purposes."
$choice = Read-Host "Do you want to delete this resource group? (Y/N)"

if ($choice -eq 'Y' -or $choice -eq 'y') {
    Write-Host "Deleting resource group '$resourceGroupName'..." -ForegroundColor Yellow
    Remove-AzResourceGroup -Name $resourceGroupName -Force
    Write-Host "Resource group deleted." -ForegroundColor Green
}
else {
    Write-Host "Resource group '$resourceGroupName' was not deleted. You can manually delete it later." -ForegroundColor Yellow
}
