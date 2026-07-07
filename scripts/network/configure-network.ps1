# ============================================
# Script: configure-network.ps1
# Purpose: Create a segmented network with
#          web and database subnets and NSG rules
# Author: Jeet Patel
# Date: 2026-07-07
# ============================================

# --- Variables ---
$resourceGroupName = "rg-automation-project"
$location = "centralindia"
$vnetName = "vnet-prod-network"
$webSubnetName = "subnet-web"
$dbSubnetName = "subnet-database"
$webNsgName = "nsg-web-tier"
$dbNsgName = "nsg-db-tier"

Write-Host "=== Configuring Production-Style Network ===" -ForegroundColor Cyan

# --- Step 1: Create NSG for Web Tier ---
Write-Host "Step 1: Creating Web Tier NSG..." -ForegroundColor Cyan

$httpRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-HTTP" `
    -Description "Allow HTTP traffic from internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 80

$httpsRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-HTTPS" `
    -Description "Allow HTTPS traffic from internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 110 `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 443

$sshRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-SSH" `
    -Description "Allow SSH for management" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 120 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22

$webNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $webNsgName `
    -SecurityRules $httpRule, $httpsRule, $sshRule

Write-Host "Web NSG created with HTTP, HTTPS, and SSH rules." -ForegroundColor Green

# --- Step 2: Create NSG for Database Tier ---
Write-Host "Step 2: Creating Database Tier NSG..." -ForegroundColor Cyan

$dbRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-SQL-From-WebSubnet" `
    -Description "Allow SQL traffic only from web subnet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix "10.1.1.0/24" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 1433

$denyInternetRule = New-AzNetworkSecurityRuleConfig `
    -Name "Deny-Internet-Inbound" `
    -Description "Block all internet traffic to DB tier" `
    -Access Deny `
    -Protocol "*" `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "*"

$dbNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $dbNsgName `
    -SecurityRules $dbRule, $denyInternetRule

Write-Host "DB NSG created - SQL allowed only from web subnet, internet blocked." -ForegroundColor Green

# --- Step 3: Create VNet with two subnets ---
Write-Host "Step 3: Creating Virtual Network with subnets..." -ForegroundColor Cyan

$webSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $webSubnetName `
    -AddressPrefix "10.1.1.0/24" `
    -NetworkSecurityGroupId $webNsg.Id

$dbSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $dbSubnetName `
    -AddressPrefix "10.1.2.0/24" `
    -NetworkSecurityGroupId $dbNsg.Id

$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $vnetName `
    -AddressPrefix "10.1.0.0/16" `
    -Subnet $webSubnet, $dbSubnet

Write-Host "VNet '$vnetName' created with two subnets." -ForegroundColor Green

# --- Step 4: Display Summary ---
Write-Host ""
Write-Host "=== Network Configuration Summary ===" -ForegroundColor Cyan
Write-Host "VNet: $vnetName (10.1.0.0/16)" -ForegroundColor White
Write-Host "  Web Subnet: $webSubnetName (10.1.1.0/24) - HTTP, HTTPS, SSH allowed" -ForegroundColor White
Write-Host "  DB Subnet:  $dbSubnetName (10.1.2.0/24) - SQL from web only, internet denied" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
