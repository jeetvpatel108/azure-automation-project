# ============================================
# Script: create-vm.ps1
# Purpose: Create an Azure Linux VM with all
#          required networking components
# Author: Jeet Patel
# Date: 2026-07-07
# ============================================

# --- Define Variables ---
$resourceGroupName = "rg-automation-project"
$location = "centralindia"
$vmName = "vm-test-auto"
$vmSize = "Standard_B2as_v2"
$adminUsername = "azureadmin"
$vnetName = "vnet-automation"
$subnetName = "subnet-default"
$nsgName = "nsg-automation"
$publicIpName = "pip-vm-test-auto"
$nicName = "nic-vm-test-auto"

# --- Step 1: Create Virtual Network and Subnet ---
Write-Host "Step 1: Creating Virtual Network and Subnet..." -ForegroundColor Cyan

$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix "10.0.1.0/24"

$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $vnetName `
    -AddressPrefix "10.0.0.0/16" `
    -Subnet $subnetConfig

Write-Host "Virtual Network '$vnetName' created." -ForegroundColor Green

# --- Step 2: Create Network Security Group with SSH rule ---
Write-Host "Step 2: Creating Network Security Group..." -ForegroundColor Cyan

$sshRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-SSH" `
    -Description "Allow SSH access" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22

$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $nsgName `
    -SecurityRules $sshRule

Write-Host "NSG '$nsgName' created with SSH rule." -ForegroundColor Green

# --- Step 3: Create Public IP Address ---
Write-Host "Step 3: Creating Public IP Address..." -ForegroundColor Cyan

$publicIp = New-AzPublicIpAddress `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $publicIpName `
    -AllocationMethod Static `
    -Sku Standard

Write-Host "Public IP '$publicIpName' created." -ForegroundColor Green

# --- Step 4: Create Network Interface ---
Write-Host "Step 4: Creating Network Interface..." -ForegroundColor Cyan

$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

$nic = New-AzNetworkInterface `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $nicName `
    -SubnetId $subnet.Id `
    -PublicIpAddressId $publicIp.Id `
    -NetworkSecurityGroupId $nsg.Id

Write-Host "NIC '$nicName' created." -ForegroundColor Green

# --- Step 5: Create VM Configuration ---
Write-Host "Step 5: Configuring and Creating VM..." -ForegroundColor Cyan

# Generate SSH key pair for the new VM
ssh-keygen -t rsa -b 4096 -f /tmp/vm-test-key -N '""'

$sshPublicKey = Get-Content /tmp/vm-test-key.pub

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

$vmConfig = Set-AzVMOperatingSystem `
    -VM $vmConfig `
    -Linux `
    -ComputerName $vmName `
    -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, (ConvertTo-SecureString "TempP@ss123!" -AsPlainText -Force))) `
    -DisablePasswordAuthentication

$vmConfig = Set-AzVMSourceImage `
    -VM $vmConfig `
    -PublisherName "Canonical" `
    -Offer "0001-com-ubuntu-server-jammy" `
    -Skus "22_04-lts-gen2" `
    -Version "latest"

$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

$vmConfig = Add-AzVMSshPublicKey `
    -VM $vmConfig `
    -KeyData $sshPublicKey `
    -Path "/home/$adminUsername/.ssh/authorized_keys"

$vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable

# --- Step 6: Deploy the VM ---
Write-Host "Deploying VM... This will take 2-5 minutes." -ForegroundColor Cyan

try {
    New-AzVM `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -VM $vmConfig

    Write-Host "VM '$vmName' created successfully!" -ForegroundColor Green

    $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
    $ip = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIpName
    Write-Host "Public IP: $($ip.IpAddress)"
    Write-Host "SSH Command: ssh -i /tmp/vm-test-key $adminUsername@$($ip.IpAddress)"
}
catch {
    Write-Host "ERROR: Failed to create VM." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
