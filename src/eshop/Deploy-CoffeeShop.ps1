#Requires -RunAsAdministrator

# Brew Bliss Coffee Shop Deployment Script
# This script automates the deployment of the Brew Bliss Coffee Shop web application

# Configuration variables
$webDeployPackageUrl = "https://github.com/jonathan-vella/Azure-Hyper-V-Lab/raw/main/src/eshop/CoffeeShopWebDeploy.zip"
$tempFolder = "C:\temp"
$webFolder = "C:\inetpub\wwwroot\BrewBlissCoffeeShop"
$appPoolName = "CoffeeShopAppPool"
$siteName = "BrewBlissCoffeeShop"
$databaseName = "CoffeeShopDB"

# Function to check if a Windows feature is installed
function Test-WindowsFeature {
    param (
        [string]$FeatureName
    )
    
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
    return $feature.State -eq "Enabled"
}

# Function to install a Windows feature if not already installed
function Install-RequiredWindowsFeature {
    param (
        [string]$FeatureName,
        [string]$DisplayName
    )
    
    if (-not (Test-WindowsFeature -FeatureName $FeatureName)) {
        Write-Host "Installing $DisplayName..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart
        Write-Host "$DisplayName installed successfully." -ForegroundColor Green
    } else {
        Write-Host "$DisplayName is already installed." -ForegroundColor Green
    }
}

# Function to check if .NET Runtime is installed
function Test-DotNetRuntime {
    param (
        [string]$Version
    )
    
    $dotnetInfo = dotnet --list-runtimes 2>$null
    return $dotnetInfo -match "$Version"
}

# Function to install .NET Runtime
function Install-DotNetRuntime {
    param (
        [string]$Version
    )
    
    Write-Host "Installing .NET $Version Runtime..." -ForegroundColor Yellow
    
    # Create a temporary directory for the installer
    $installerDir = Join-Path $env:TEMP "dotnet$Version"
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
    
    # Download the .NET Runtime installer
    $installerUrl = "https://dotnet.microsoft.com/download/dotnet/$Version/runtime"
    $installerPath = Join-Path $installerDir "dotnet-installer.exe"
    
    Write-Host "Downloading .NET $Version installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    
    # Run the installer
    Write-Host "Running .NET $Version installer..."
    Start-Process -FilePath $installerPath -ArgumentList "/quiet", "/norestart" -Wait
    
    Write-Host ".NET $Version Runtime installed successfully." -ForegroundColor Green
}

# Function to check if ASP.NET Core Module is installed
function Test-AspNetCoreModule {
    $modules = Get-WebGlobalModule
    return ($modules | Where-Object { $_.Name -eq "AspNetCoreModuleV2" }) -ne $null
}

# Function to install ASP.NET Core Module
function Install-AspNetCoreModule {
    Write-Host "Installing ASP.NET Core Module for IIS..." -ForegroundColor Yellow
    
    # Create a temporary directory for the installer
    $installerDir = Join-Path $env:TEMP "aspnetcore-module"
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
    
    # Download the ASP.NET Core Module installer
    $installerUrl = "https://dotnet.microsoft.com/download/dotnet/thank-you/runtime-aspnetcore-9.0.0-windows-hosting-bundle-installer"
    $installerPath = Join-Path $installerDir "dotnet-hosting-bundle.exe"
    
    Write-Host "Downloading ASP.NET Core Module installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    
    # Run the installer
    Write-Host "Running ASP.NET Core Module installer..."
    Start-Process -FilePath $installerPath -ArgumentList "/quiet", "/norestart" -Wait
    
    # Restart IIS to apply changes
    Write-Host "Restarting IIS to apply changes..."
    iisreset /restart
    
    Write-Host "ASP.NET Core Module installed successfully." -ForegroundColor Green
}

# Function to test database connection
function Test-SqlConnection {
    param (
        [string]$ServerName
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = "Server=$ServerName;Database=master;Integrated Security=True;Connect Timeout=5"
        $connection.Open()
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

# Function to create SQL database
function Create-Database {
    param (
        [string]$ServerName,
        [string]$DatabaseName
    )
    
    try {
        $query = "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '$DatabaseName') CREATE DATABASE [$DatabaseName]"
        
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = "Server=$ServerName;Database=master;Integrated Security=True"
        $connection.Open()
        
        $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
        $command.ExecuteNonQuery()
        $connection.Close()
        
        Write-Host "Database '$DatabaseName' created or already exists." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error creating database: $_" -ForegroundColor Red
        return $false
    }
}

# Function to update connection string in appsettings.json
function Update-ConnectionString {
    param (
        [string]$AppSettingsPath,
        [string]$ServerName,
        [string]$DatabaseName
    )
    
    try {
        $appSettings = Get-Content -Path $AppSettingsPath -Raw | ConvertFrom-Json
        $appSettings.ConnectionStrings.DefaultConnection = "Server=$ServerName;Database=$DatabaseName;Trusted_Connection=True;MultipleActiveResultSets=true"
        $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $AppSettingsPath
        Write-Host "Connection string updated successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error updating connection string: $_" -ForegroundColor Red
    }
}

# Function to run database migrations
function Run-DatabaseMigrations {
    param (
        [string]$ProjectPath
    )
    
    try {
        Set-Location -Path (Split-Path -Parent $ProjectPath)
        Write-Host "Running database migrations..." -ForegroundColor Yellow
        $output = & dotnet ef database update --project (Split-Path -Leaf $ProjectPath) 2>&1
        Write-Host "Database migrations applied successfully." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error applying database migrations: $_" -ForegroundColor Red
        return $false
    }
}

# Main Script Execution
Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "      Brew Bliss Coffee Shop Deployment Script" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host

# 1. Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check and install IIS
Install-RequiredWindowsFeature -FeatureName "IIS-WebServerRole" -DisplayName "IIS Web Server"
Install-RequiredWindowsFeature -FeatureName "IIS-ASPNET45" -DisplayName "ASP.NET 4.5"
Install-RequiredWindowsFeature -FeatureName "IIS-ApplicationInit" -DisplayName "Application Initialization"
Install-RequiredWindowsFeature -FeatureName "IIS-WebSockets" -DisplayName "WebSockets Protocol"

# Check and install .NET 9.0 Runtime
if (-not (Test-DotNetRuntime -Version "9.0")) {
    Install-DotNetRuntime -Version "9.0"
} else {
    Write-Host ".NET 9.0 Runtime is already installed." -ForegroundColor Green
}

# Check and install ASP.NET Core Module
if (-not (Test-AspNetCoreModule)) {
    Install-AspNetCoreModule
} else {
    Write-Host "ASP.NET Core Module is already installed." -ForegroundColor Green
}

# 2. Get SQL Server name
$defaultSqlServer = "sql01"
$sqlServerName = Read-Host "Enter SQL Server name (default: $defaultSqlServer)"
if ([string]::IsNullOrWhiteSpace($sqlServerName)) {
    $sqlServerName = $defaultSqlServer
}

# Test SQL Server connection
Write-Host "Testing connection to SQL Server '$sqlServerName'..." -ForegroundColor Yellow
if (-not (Test-SqlConnection -ServerName $sqlServerName)) {
    Write-Host "Cannot connect to SQL Server '$sqlServerName'. Please check the server name and ensure it is running." -ForegroundColor Red
    exit 1
}

# 3. Create temp directory if it doesn't exist
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
}

# 4. Download the web deploy package
$webDeployPackagePath = Join-Path $tempFolder "CoffeeShop.WebDeploy.zip"
Write-Host "Downloading web deployment package..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $webDeployPackageUrl -OutFile $webDeployPackagePath
    Write-Host "Downloaded web deployment package to $webDeployPackagePath" -ForegroundColor Green
} catch {
    Write-Host "Error downloading web deployment package: $_" -ForegroundColor Red
    exit 1
}

# 5. Create the website directory if it doesn't exist
if (-not (Test-Path -Path $webFolder)) {
    New-Item -ItemType Directory -Path $webFolder -Force | Out-Null
    Write-Host "Created web folder at $webFolder" -ForegroundColor Green
}

# 6. Extract the web deploy package
Write-Host "Extracting web deployment package..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $webDeployPackagePath -DestinationPath $webFolder -Force
    Write-Host "Extracted web deployment package to $webFolder" -ForegroundColor Green
} catch {
    Write-Host "Error extracting web deployment package: $_" -ForegroundColor Red
    exit 1
}

# 7. Create the database
Write-Host "Creating database '$databaseName' on SQL Server '$sqlServerName'..." -ForegroundColor Yellow
if (-not (Create-Database -ServerName $sqlServerName -DatabaseName $databaseName)) {
    Write-Host "Failed to create database. Deployment aborted." -ForegroundColor Red
    exit 1
}

# 8. Update the connection string
$appSettingsPath = Join-Path $webFolder "appsettings.json"
Write-Host "Updating connection string in $appSettingsPath..." -ForegroundColor Yellow
Update-ConnectionString -AppSettingsPath $appSettingsPath -ServerName $sqlServerName -DatabaseName $databaseName

# 9. Configure IIS
Write-Host "Configuring IIS..." -ForegroundColor Yellow

# Create Application Pool if it doesn't exist
Import-Module WebAdministration
if (-not (Test-Path "IIS:\AppPools\$appPoolName")) {
    Write-Host "Creating Application Pool '$appPoolName'..." -ForegroundColor Yellow
    New-WebAppPool -Name $appPoolName
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value ""
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedPipelineMode" -Value "Integrated"
    Write-Host "Application Pool '$appPoolName' created." -ForegroundColor Green
} else {
    Write-Host "Application Pool '$appPoolName' already exists." -ForegroundColor Green
}

# Create Website if it doesn't exist
if (-not (Get-Website -Name $siteName)) {
    Write-Host "Creating Website '$siteName'..." -ForegroundColor Yellow
    New-Website -Name $siteName -PhysicalPath $webFolder -ApplicationPool $appPoolName -Force
    Write-Host "Website '$siteName' created." -ForegroundColor Green
} else {
    Write-Host "Website '$siteName' already exists. Updating configuration..." -ForegroundColor Yellow
    Set-ItemProperty "IIS:\Sites\$siteName" -Name "physicalPath" -Value $webFolder
    Set-ItemProperty "IIS:\Sites\$siteName" -Name "applicationPool" -Value $appPoolName
    Write-Host "Website '$siteName' configuration updated." -ForegroundColor Green
}

# 10. Set permissions
Write-Host "Setting folder permissions..." -ForegroundColor Yellow

# Grant IIS_IUSRS permissions
$acl = Get-Acl $webFolder
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $webFolder $acl

# Grant application pool identity permissions
$appPoolIdentity = "IIS AppPool\$appPoolName"
$acl = Get-Acl $webFolder
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($appPoolIdentity, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $webFolder $acl

Write-Host "Permissions set successfully." -ForegroundColor Green

# 11. Run database migrations
$projectPath = Join-Path $webFolder "CoffeeShop.csproj"
if (Test-Path $projectPath) {
    Run-DatabaseMigrations -ProjectPath $projectPath
} else {
    Write-Host "Project file not found. Skipping database migrations." -ForegroundColor Yellow
}

# 12. Test the application
Write-Host "Testing application..." -ForegroundColor Yellow
$url = "http://localhost"
try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "Application is running successfully! You can access it at $url" -ForegroundColor Green
    } else {
        Write-Host "Application returned status code $($response.StatusCode). Please check the logs for more information." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error testing application: $_" -ForegroundColor Red
    Write-Host "Please check IIS logs and Event Viewer for more information." -ForegroundColor Yellow
}

Write-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "      Brew Bliss Coffee Shop Deployment Complete" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Website URL: http://localhost" -ForegroundColor White
Write-Host "Website Physical Path: $webFolder" -ForegroundColor White
Write-Host "Database: $databaseName on $sqlServerName" -ForegroundColor White
Write-Host "=======================================================" -ForegroundColor Cyan
