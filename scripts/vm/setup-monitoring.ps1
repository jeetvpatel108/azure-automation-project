# ============================================
# Script: setup-monitoring.ps1
# Purpose: Set up Azure Monitor alerts for
#          automation job failures
# Author: Jeet Patel
# Date: 2026-07-07
# ============================================

# --- Variables ---
$resourceGroupName = "rg-automation-project"
$location = "eastus"
$automationAccountName = "aa-jeet-automation"
$actionGroupName = "ag-email-alerts"
$alertRuleName = "alert-automation-failure"
$emailAddress = "jeetvpatel108@gmail.com"

Write-Host "=== Setting Up Monitoring and Alerts ===" -ForegroundColor Cyan

# --- Step 1: Create Action Group (who gets notified) ---
Write-Host "Step 1: Creating Action Group..." -ForegroundColor Cyan

$emailReceiver = New-AzActionGroupEmailReceiverObject `
    -Name "JeetEmail" `
    -EmailAddress $emailAddress

$actionGroup = Set-AzActionGroup `
    -ResourceGroupName $resourceGroupName `
    -Name $actionGroupName `
    -ShortName "EmailAlert" `
    -GroupReceiver @{ emailReceivers = @($emailReceiver) } `
    -Location "Global" `
    -ErrorAction Stop

Write-Host "Action Group '$actionGroupName' created." -ForegroundColor Green

# --- Step 2: Get Automation Account Resource ID ---
Write-Host "Step 2: Getting Automation Account details..." -ForegroundColor Cyan

$automationAccount = Get-AzAutomationAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $automationAccountName `
    -ErrorAction Stop

$resourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$automationAccountName"

Write-Host "Automation Account Resource ID retrieved." -ForegroundColor Green

# --- Step 3: Create Alert Rule ---
Write-Host "Step 3: Creating Alert Rule for failed jobs..." -ForegroundColor Cyan

$condition = New-AzMetricAlertRuleV2Criteria `
    -MetricName "TotalJob" `
    -MetricNamespace "Microsoft.Automation/automationAccounts" `
    -TimeAggregation Total `
    -Operator GreaterThan `
    -Threshold 0 `
    -DimensionSelection @(
        New-AzMetricAlertRuleV2DimensionSelection `
            -DimensionName "Status" `
            -ValuesToInclude "Failed"
    )

Add-AzMetricAlertRuleV2 `
    -ResourceGroupName $resourceGroupName `
    -Name $alertRuleName `
    -TargetResourceId $resourceId `
    -Condition $condition `
    -ActionGroupId $actionGroup.Id `
    -WindowSize (New-TimeSpan -Minutes 5) `
    -Frequency (New-TimeSpan -Minutes 5) `
    -Severity 2 `
    -Description "Alert when automation runbook jobs fail" `
    -ErrorAction Stop

Write-Host "Alert Rule '$alertRuleName' created." -ForegroundColor Green

# --- Summary ---
Write-Host ""
Write-Host "=== Monitoring Setup Summary ===" -ForegroundColor Cyan
Write-Host "Action Group  : $actionGroupName" -ForegroundColor White
Write-Host "Email Target  : $emailAddress" -ForegroundColor White
Write-Host "Alert Rule    : $alertRuleName" -ForegroundColor White
Write-Host "Monitors      : Failed automation jobs" -ForegroundColor White
Write-Host "Check Interval: Every 5 minutes" -ForegroundColor White
Write-Host "=================================" -ForegroundColor Cyan
