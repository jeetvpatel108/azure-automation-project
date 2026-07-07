# ============================================
# Script: create-storage-account.ps1
# Purpose: Create an Azure Storage Account
# Author: Jeet Patel
# Date: 2026-07-07
# ============================================

# --- Define Variables ---
$resourceGroupName = "rg-automation-project"
$location = "centralindia"
$storageAccountName = "stautomationjeet2026"
$skuName = "Standard_LRS"

# --- Display what we are about to do ---
Write-Host "=== Creating Azure Storage Account ===" -ForegroundColor Cyan
Write-Host "Resource Group : $resourceGroupName"
Write-Host "Location       : $location"
Write-Host "Account Name   : $storageAccountName"
Write-Host "SKU            : $skuName"
Write-Host "=======================================" -ForegroundColor Cyan

# --- Check if the Resource Group exists ---
$rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "ERROR: Resource Group '$resourceGroupName' not found!" -ForegroundColor Red
    exit 1
}
Write-Host "Resource Group found. Proceeding..." -ForegroundColor Green

# --- Check if Storage Account already exists ---
$existingAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue
if ($existingAccount) {
    Write-Host "Storage Account '$storageAccountName' already exists. Skipping creation." -ForegroundColor Yellow
    exit 0
}

# --- Create the Storage Account ---
Write-Host "Creating Storage Account... This may take a moment." -ForegroundColor Cyan
try {
    $storageAccount = New-AzStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $storageAccountName `
        -Location $location `
        -SkuName $skuName `
        -Kind "StorageV2" `
        -AccessTier "Hot"

    Write-Host "Storage Account '$storageAccountName' created successfully!" -ForegroundColor Green
    Write-Host "Primary Endpoint: $($storageAccount.PrimaryEndpoints.Blob)"
}
catch {
    Write-Host "ERROR: Failed to create Storage Account." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
# Version: 1.0
