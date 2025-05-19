# Update-GitHubUrls.ps1
# This script updates all GitHub URLs in the template files to match your GitHub username

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$GitHubUsername,

    [Parameter(Mandatory = $false)]
    [string]$RepositoryName = "Azure-Hyper-V-Lab"
)

$files = @(
    "..\..\src\bicep\main.bicep",
    "..\..\modules\vm-extensions.bicep",
    "..\..\src\parameters\main.parameters.json",
    "..\..\src\parameters\main.secure.parameters.json",
    "..\..\README.md",
    "..\..\QUICKSTART.md"
)

$placeholder = "your-username"
$originalRepo = "jonathan-vella/Azure-Hyper-V-Lab"

Write-Host "Updating GitHub URLs to use username: $GitHubUsername" -ForegroundColor Cyan

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        
        # Read file content
        $content = Get-Content -Path $file -Raw
        
        # Replace placeholders with the provided GitHub username
        $updatedContent = $content -replace "github\.com/$placeholder/$RepositoryName", "github.com/$GitHubUsername/$RepositoryName"
        $updatedContent = $updatedContent -replace "githubusercontent\.com/$placeholder/$RepositoryName", "githubusercontent.com/$GitHubUsername/$RepositoryName"
        
        # Replace any remaining original repo references
        $updatedContent = $updatedContent -replace "github\.com/$originalRepo", "github.com/$GitHubUsername/$RepositoryName"
        $updatedContent = $updatedContent -replace "githubusercontent\.com/$originalRepo", "githubusercontent.com/$GitHubUsername/$RepositoryName"
        
        # Write updated content back to the file
        Set-Content -Path $file -Value $updatedContent
        
        Write-Host "Updated $file" -ForegroundColor Green
    }
    else {
        Write-Host "Warning: File not found - $file" -ForegroundColor Yellow
    }
}

# Update the Deploy to Azure button URL in README.md
$readmePath = "..\..\README.md"
if (Test-Path $readmePath) {
    $readmeContent = Get-Content -Path $readmePath -Raw
    
    # Extract the deploy to Azure button link
    $pattern = "(https://portal\.azure\.com/#create/Microsoft\.Template/uri/.*?)\)"
    if ($readmeContent -match $pattern) {
        $originalUrl = $matches[1]
        
        # Create the new URL with the updated GitHub username
        $encodedUri = [Uri]::EscapeDataString("https://raw.githubusercontent.com/$GitHubUsername/$RepositoryName/main/main.json")
        $newUrl = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedUri"
        
        # Replace the URL in the README
        $updatedReadmeContent = $readmeContent -replace [regex]::Escape($originalUrl), $newUrl
        Set-Content -Path $readmePath -Value $updatedReadmeContent
        
        Write-Host "Updated Deploy to Azure button in README.md" -ForegroundColor Green
    }
}

Write-Host "`nAll GitHub URLs have been updated to use: $GitHubUsername/$RepositoryName" -ForegroundColor Green
Write-Host "Remember to push these changes to your GitHub repository." -ForegroundColor Cyan
