# Builder
This document breaks down the different parts of the basic template and explains what the different parts are doing. If you just want to try out the template go to the [how to build it section](#how-to-build-it).

Packer on Azure has 2 options for building images, `azure-arm` and `azure-chroot`. The simpler one to use is `azure-arm` so we start the builder section by specifying that. Note that I use the word section throughout this write-up but it is only a logical division and everything under [Builder](#builder) is all included in one section in json. 
```json
"type": "azure-arm",
```
## Authentication
Then we have to specify our authentication mechanism. I've used a Service Principal as I'm planning to run this template as part of a DevOps pipeline but for local development [interactive login](https://www.packer.io/docs/builders/azure/#azure-active-directory-interactive-login) would probably be easier. To specify the service principal to use the following fields are needed:
```json
"client_id": "{{user `client_id`}}",
"client_secret": "{{user `client_secret`}}",
"tenant_id": "{{user `tenant_id`}}",
"subscription_id": "{{user `subscription_id`}}",
```
## Custom Image Storage
After that we have to specify where the completed image will be stored. One can let Packer create it's own Resource Group and it will put all the stuff it generates in there, or you can specify a Resource Group for Packer to use. I prefer to let Packer create it's own Resource Group as I've found it easier to cleanup by just deleting the whole Resource Group. Note that Packer already does it's own clean-up but on occassion I've had the clean-up fail due to an Azure-level error so I had to manually go and delete Packer's Resource Group.

We also need to specify the name of the image produced. I use the built-in iso function to put the date in the name so I can easily identify when an image was created. For a 24-hour format the template follows this format {{isotime "20060102150405"}}, in json the fields look like this:
```json
"managed_image_resource_group_name": "{{user `result_rg`}}",
"managed_image_name": "windows-template-{{isotime \"20060102150405\"}}",
```
## Base Image
Then we have to specify the base image to use in the template. In my finished template I used variables instead of static values in order to easily switch to a different version of Windows without changing the template but when filled in-line the fields for specifying the image look like this:
```json
"os_type": "Windows",
"image_publisher": "MicrosoftWindowsServer",
"image_offer": "WindowsServer",
"image_sku": "2019-Datacenter",
```
## Communicator
Up to this point with what we have, we've instructed Packer to create a Windows VM using ARM. Now we have to customize the VM by specifying a communicator to use and the code that needs to be run on the VM.
The typical communicator used with a Windows VM is WinRM so we specify WinRM as follows. Use SSL and and WinRM insecure are set to true so we use HTTPS and so WinRM does not check the server certificate chain and host name. Packer generates a certificate and stores in KeyVault during its run so not having these options set to true causes WinRM to timeout. The WinRM timeout is how long Packer keeps trying to connect using WinRM. In normal circumstances 5 minutes is enough but sometimes a WinRM timeout error occurs due to a cloud-level issue so it would be worth increasing this timeout and giving it a second try.
```json
"communicator": "winrm",
"winrm_use_ssl": true,
"winrm_insecure": true,
"winrm_timeout": "5m",
"winrm_username": "packer",
```
## Azure-specific Settings
The final part of the builder section of the template contains some Azure-specific settings. We can specify tags to be added to the image in Azure. I've added a Build ID that is automatically filled in by my DevOps pipeline but this can be passed in through a user variable or omitted altogether. Some other tags I usually add are Project, Environment, and Billing. Read the official [docs on tags](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources#required-access) for more ideas. Tags don't serve a functional purpose for Packer and are there for convenience.
```json
"azure_tags": {
    "DevOps BuildId": "{{user `tags_build_id`}}"
},
```
In this section we also specify the Azure region in which the image will be stored, this is mandatory if we don't specify a Resource Group for Packer to use in the [Custom Image Storage](#custom-image-storage) section.

Then we specify a VM Size for the VM that Packer will create. A WinRM timeout issue has come up with some VM sizes so the recommended one to use is a size without S in the name like Standard_D2_v2 instead of Standard_DS2_v2.

Finally, Packer can be told not to wait for cleanup by specifying async_resourcegroup_delete: true. When true, Packer sends the deletion command to Azure but doesn't wait for it to go through.

The completed last section of the builder then looks like this:
```json
"location": "{{user `azure_location`}}",
"vm_size": "Standard_D2_v2",
"async_resourcegroup_delete": "true"
```
# Provisioners
At this point in time Packer will build the VM with an [ARM](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview) template then connect to it with WinRM. When connected it will execute the steps specified here in sequential order. The most common step that you almost always would want to run is to make the image generic with sysprep and that would be the following commands:
```json
"type": "powershell",
"inline": [
  "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
  "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; Write-Output $imageState.ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Start-Sleep -s 10 } else { break } }"
]
```
In my example template you will see 3 lines that I ran before but those are circumstancial and I only needed to add them because I was building my template with a hosted VM and Azure DevOps

# How to build it
The template requires the following environment variables as input
- `ARM_CLIENT_ID`: Service Principal ID
- `ARM_CLIENT_SECRET`: Service Principal Secret
- `ARM_TENANT_ID`: Azure Subscription Tenant ID
- `ARM_SUBSCRIPTION_ID`: Azure Subscription ID
- `RESULT_RG`: Resource Group where the image will be stored after creation
- `IMAGE_PUBLISHER`: Publisher of the base image to use
- `IMAGE_OFFER`: The offer of the base image to use
- `IMAGE_SKU`: SKU of the base image to use
- `TAGS_BUILD_ID`: The tag to be added to the image in Azure
- `AZURE_LOCATION`: The Azure Region where the image will be stored
- `SAMPLE_VAR`: This is used for demo purposes only and any value can be passed

Building it:
1. Change directory to the root of this repo.
2. Validate the template: 
``` shell
packer validate basic-template/basic-template.json
```
3. Build the template:
``` shell
packer build basic-template/basic-template.json
```