$VMLocalAdminUser = "LocalAdminUser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "1S1wf^nCt&Bpj8PI" -AsPlainText -Force
$ResourceGroupName = "ciswinprep-rg"
$LocationName = "westeurope"
$ComputerName = "ciswinprep"
$VMName = "ciswinprep"
$VMSize = "Standard_D2_v2"

$NetworkName = "ciswinprepnet"
$NICName = "ciswinprepnic"
$SubnetName = "ciswinprepsubnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix = "10.0.0.0/16"

$PublisherName = 'center-for-internet-security-inc' 
$Offer = 'cis-windows-server-2019-v1-0-0-l1' 
$Sku = 'cis-ws2019-l1' 
$Version = '1.0.8'

New-AzureRmResourceGroup `
   -Name $ResourceGroupName `
   -Location $LocationName 

$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $Offer -Skus $Sku -Version $Version
Set-AzureRmVMPlan -VM $VirtualMachine -Publisher $PublisherName -Product $Offer -Name $Sku

New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose

Set-AzVMCustomScriptExtension `
    -ResourceGroupName $ResourceGroupName `
    -Name "CustomScriptExtension" `
    -VMName $VMName `
    -Location $LocationName `
    -FileUri "https://storageonmsdn.blob.core.windows.net/packer/configure-winrm.ps1" `
    -Run 'configure-winrm.ps1'

#Initialize Variables to be used
$vmName = "ciswinprep"
$ResourceGroupName = "ciswinprep-rg"
# $storageAccountName = 'storageonmsdn'
$vm = Get-AzVM -Name $VMName `
   -ResourceGroupName $ResourceGroupName

$disk = Get-AzDisk -ResourceGroupName $resourceGroupName `
  -DiskName $vm.StorageProfile.OsDisk.Name

$snapshot =  New-AzSnapshotConfig -SourceUri $disk.Id -Location $LocationName -CreateOption copy -OsType Windows

New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $ResourceGroupName

$ImageName = "cis-pwsh-vhd-20200604"
$LocationName = "westeurope"
$VMName = "ciswinprep"
$ResourceGroupName = "ciswinprep-rg"
$vm = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName
$image = New-AzImageConfig -Location $LocationName -SourceVirtualMachineId $vm.Id
New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $ResourceGroupName