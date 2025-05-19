# Check-ParameterFiles.ps1
# This script checks parameter files for ARM expression usage where literal values are expected

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$ParameterFiles = @(
        "..\..\src\parameters\main.parameters.json",
        "..\..\src\parameters\main.secure.parameters.json"
    )
)

Write-Host "Checking parameter files for invalid ARM expressions..." -ForegroundColor Cyan

$invalidExpressionsFound = $false

foreach ($parameterFile in $ParameterFiles) {
    if (Test-Path $parameterFile) {
        Write-Host "Checking $parameterFile..." -ForegroundColor Yellow
        
        $content = Get-Content -Path $parameterFile -Raw
        
        # Check for ARM expressions in the location parameter
        if ($content -match '"location":\s*{\s*"value":\s*"\[resourceGroup\(\)\.location\]"') {
            Write-Host "⚠️ Warning: ARM expression found for location parameter in $parameterFile" -ForegroundColor Red
            Write-Host "   Parameter files require literal values (e.g., 'swedencentral'), not ARM expressions like [resourceGroup().location]" -ForegroundColor Red
            Write-Host "   This can cause deployment errors. Please replace with an actual Azure region." -ForegroundColor Red
            $invalidExpressionsFound = $true
        }
        
        # Check for other common ARM expressions
        $armExpressions = @(
            '\[subscription\(\)',
            '\[parameters\(',
            '\[variables\(',
            '\[concat\(',
            '\[deployment\(',
            '\[reference\('
        )
        
        foreach ($expression in $armExpressions) {
            if ($content -match $expression) {
                Write-Host "⚠️ Warning: ARM expression '$expression' found in $parameterFile" -ForegroundColor Red
                Write-Host "   Parameter files require literal values, not ARM expressions" -ForegroundColor Red
                $invalidExpressionsFound = $true
            }
        }
        
        if (!$invalidExpressionsFound) {
            Write-Host "✅ No invalid ARM expressions found in $parameterFile" -ForegroundColor Green
        }
    }
    else {
        Write-Host "⚠️ Parameter file not found: $parameterFile" -ForegroundColor Yellow
    }
}

if ($invalidExpressionsFound) {
    Write-Host "`nPlease fix the identified issues before deploying the templates." -ForegroundColor Red
}
else {
    Write-Host "`nAll parameter files passed validation!" -ForegroundColor Green
}
