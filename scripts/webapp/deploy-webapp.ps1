# ============================================
# Script: deploy-webapp.ps1
# Purpose: Deploy an Azure Web App using
#          App Service (managed platform)
# Author: Jeet Patel
# Date: 2026-07-07
# ============================================

# --- Variables ---
$resourceGroupName = "rg-automation-project"
$location = "centralindia"
$appServicePlanName = "asp-automation-project"
$webAppName = "webapp-jeet-auto-2026"
$skuName = "F1"

Write-Host "=== Deploying Azure Web App ===" -ForegroundColor Cyan
Write-Host "Resource Group    : $resourceGroupName"
Write-Host "App Service Plan  : $appServicePlanName"
Write-Host "Web App Name      : $webAppName"
Write-Host "SKU               : $skuName (Free Tier)"
Write-Host "================================" -ForegroundColor Cyan

# --- Step 1: Create App Service Plan ---
Write-Host "Step 1: Creating App Service Plan..." -ForegroundColor Cyan

$existingPlan = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName -ErrorAction SilentlyContinue
if ($existingPlan) {
    Write-Host "App Service Plan already exists. Skipping." -ForegroundColor Yellow
}
else {
    $plan = New-AzAppServicePlan `
        -ResourceGroupName $resourceGroupName `
        -Name $appServicePlanName `
        -Location $location `
        -Tier "Free" `
        -Linux

    Write-Host "App Service Plan '$appServicePlanName' created." -ForegroundColor Green
}

# --- Step 2: Create Web App ---
Write-Host "Step 2: Creating Web App..." -ForegroundColor Cyan

$existingApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -ErrorAction SilentlyContinue
if ($existingApp) {
    Write-Host "Web App already exists. Skipping." -ForegroundColor Yellow
}
else {
    $webApp = New-AzWebApp `
        -ResourceGroupName $resourceGroupName `
        -Name $webAppName `
        -AppServicePlan $appServicePlanName `
        -Location $location

    Write-Host "Web App '$webAppName' created." -ForegroundColor Green
}

# --- Step 3: Configure App Settings ---
Write-Host "Step 3: Configuring App Settings..." -ForegroundColor Cyan

$appSettings = @{
    "ENVIRONMENT" = "Development"
    "PROJECT"     = "Azure Automation Project"
    "AUTHOR"      = "Jeet Patel"
}

Set-AzWebApp `
    -ResourceGroupName $resourceGroupName `
    -Name $webAppName `
    -AppSettings $appSettings

Write-Host "App Settings configured." -ForegroundColor Green

# --- Step 4: Display Summary ---
$app = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName

Write-Host ""
Write-Host "=== Web App Deployment Summary ===" -ForegroundColor Cyan
Write-Host "Web App Name : $webAppName" -ForegroundColor White
Write-Host "URL          : https://$webAppName.azurewebsites.net" -ForegroundColor White
Write-Host "State        : $($app.State)" -ForegroundColor White
Write-Host "SKU          : Free (F1)" -ForegroundColor White
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Visit your app at: https://$webAppName.azurewebsites.net" -ForegroundColor Green
