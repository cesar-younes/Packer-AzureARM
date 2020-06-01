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

#Create a snapshot of Windows VM disk

#Initialize Variables to be used
$resourceGroupName = 'rg-adp-simulation-templates' 
$location = 'westeurope' 
$vmName = 'simwinbase'
$snapshotName = 'cisWindowsServer2019WinRMBasicAuth'
$storageAccountName = 'storageadpsimtemplates'
$managedDiskId = '/subscriptions/5923282c-c394-42a1-9a37-9e898a8e16a7/resourceGroups/RG-ADP-SIMULATION-TEMPLATES/providers/Microsoft.Compute/disks/simwinbase_OsDisk_1_744db9c652d143c3b5f2c156f7e2765f'

$vm = az vm get-instance-view -g $resourceGroupName -n $vmName
$storageAccount = az storage account show -g $resourceGroupName -n $storageAccountName

$snapshot =  New-AzSnapshotConfig -SourceUri $managedDiskId -Location $location -CreateOption copy -StorageAccountId $storageAccount.Id

New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName


#Provide the subscription Id of the subscription where snapshot is created
$subscriptionId = "5923282c-c394-42a1-9a37-9e898a8e16a7"

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/en-us/Az.Storage/storage-dotnet-shared-access-signature-part-1
$sasExpiryDuration = "3600"
#Name of the storage container where the downloaded snapshot will be stored
$storageContainerName = "winsimsnapshots"

#Provide the key of the storage account where you want to copy snapshot. 
$storageAccountKey = 'X09iwqpsHHg7tIIEH/p2ldiLahBiz5hoM02obJOxqdCSaq9HiaHGsHPZyWxl5N5g55IQ4yy+vD8Tars+YboigA=='

#Provide the name of the VHD file to which snapshot will be copied.
$destinationVHDFileName = "cisWindowsServer2019WinRMBasicAuth.vhd"


# Set the context to the subscription Id where Snapshot is created
Select-AzSubscription -SubscriptionId $SubscriptionId

#Generate the SAS for the snapshot 
$sas = Grant-AzSnapshotAccess -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName  -DurationInSecond $sasExpiryDuration -Access Read
#Create the context for the storage account which will be used to copy snapshot to the storage account 
$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

#Copy the snapshot to the storage account 
Start-AzStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName