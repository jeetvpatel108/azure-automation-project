# ============================================
# Script: setup-automation-account.ps1
# Purpose: Create Azure Automation Account
#          and import a sample runbook
# Author: Jeet Patel
# Date: 2026-07-07
# ============================================

# --- Variables ---
$resourceGroupName = "rg-automation-project"
$location = "eastus"
$automationAccountName = "aa-jeet-automation"

Write-Host "=== Setting Up Azure Automation ===" -ForegroundColor Cyan

# --- Step 1: Create Automation Account ---
Write-Host "Step 1: Creating Automation Account..." -ForegroundColor Cyan

$existingAA = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -Name $automationAccountName -ErrorAction SilentlyContinue
if ($existingAA) {
    Write-Host "Automation Account already exists. Skipping." -ForegroundColor Yellow
}
else {
      try {
        New-AzAutomationAccount `
            -ResourceGroupName $resourceGroupName `
            -Name $automationAccountName `
            -Location $location `
	    -ErrorAction Stop

        Write-Host "Automation Account '$automationAccountName' created." -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to create Automation Account." -ForegroundColor Red
        Write-Host $_.Exception.Message
        exit 1
    }

}

# --- Step 2: Create a sample runbook ---
Write-Host "Step 2: Creating sample runbook..." -ForegroundColor Cyan

$runbookName = "Check-ResourceHealth"
$runbookContent = @'
# Runbook: Check-ResourceHealth
# Purpose: List all resources and their status in the resource group

Connect-AzAccount -Identity

$resourceGroupName = "rg-automation-project"
$resources = Get-AzResource -ResourceGroupName $resourceGroupName

Write-Output "=== Resource Health Check ==="
Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "Resource Group: $resourceGroupName"
Write-Output "Total Resources: $($resources.Count)"
Write-Output ""

foreach ($resource in $resources) {
    Write-Output "Name: $($resource.Name)"
    Write-Output "Type: $($resource.ResourceType)"
    Write-Output "Location: $($resource.Location)"
    Write-Output "---"
}

Write-Output "=== Health Check Complete ==="
'@

$runbookPath = "/tmp/Check-ResourceHealth.ps1"
$runbookContent | Out-File -FilePath $runbookPath -Encoding UTF8

Import-AzAutomationRunbook `
    -ResourceGroupName $resourceGroupName `
    -AutomationAccountName $automationAccountName `
    -Name $runbookName `
    -Type PowerShell `
    -Path $runbookPath `
    -Published `
    -Force

Write-Host "Runbook '$runbookName' created and published." -ForegroundColor Green

# --- Step 3: Create a schedule ---
Write-Host "Step 3: Creating daily schedule..." -ForegroundColor Cyan

$scheduleName = "DailyHealthCheck"
$startTime = (Get-Date).AddDays(1).Date.AddHours(9)

New-AzAutomationSchedule `
    -ResourceGroupName $resourceGroupName `
    -AutomationAccountName $automationAccountName `
    -Name $scheduleName `
    -StartTime $startTime `
    -DayInterval 1 `
    -Description "Runs resource health check daily at 9 AM"

Write-Host "Schedule '$scheduleName' created - runs daily at 9:00 AM." -ForegroundColor Green

# --- Step 4: Link runbook to schedule ---
Write-Host "Step 4: Linking runbook to schedule..." -ForegroundColor Cyan

Register-AzAutomationScheduledRunbook `
    -ResourceGroupName $resourceGroupName `
    -AutomationAccountName $automationAccountName `
    -RunbookName $runbookName `
    -ScheduleName $scheduleName

Write-Host "Runbook linked to schedule." -ForegroundColor Green

# --- Summary ---
Write-Host ""
Write-Host "=== Automation Setup Summary ===" -ForegroundColor Cyan
Write-Host "Automation Account : $automationAccountName" -ForegroundColor White
Write-Host "Runbook            : $runbookName" -ForegroundColor White
Write-Host "Schedule           : $scheduleName (Daily at 9:00 AM)" -ForegroundColor White
Write-Host "=================================" -ForegroundColor Cyan
