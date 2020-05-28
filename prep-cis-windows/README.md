# Custom image before Packer

Normally Packer is what creates a custom image for you but there are cases when an image needs to be prepped to make it accessible for Packer. I faced this issue when I was trying to create a Packer template with CIS Windows 2019 Benchamark L1 as the base image but Packer couldn't access it due to that image having WinRM Basic Authentication disabled. 

The included script file `create-cis-image.ps1` will create a CIS Windows VM from the Azure Marketplace, enable Basic Authentication on it, run sysprep, then create an image from it to be used in the Packer template
Creating the image uses Azure Resource Manager(ARM) and the template is taken from the official repo [here](https://github.com/Azure/azure-quickstart-templates/tree/master/201-vm-custom-script-windows)