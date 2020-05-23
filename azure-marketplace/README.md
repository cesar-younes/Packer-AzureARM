# Azure Marketplace Image as base image
There are times when an Azure Marketplace image is needed as the starting base image of a Packer build. 

## Builder for marketplace
The Packer template is the same as the basic template with the addition of one more section called plan-info in the `Builder` part of the template. Certain images require that a version of the image be specified so the modified image details with plan-info look like this
```json
"image_publisher": "{{user `image_publisher`}}",
"image_offer": "{{user `image_offer`}}",
"image_sku": "{{user `image_sku`}}",
"image_version": "{{user `image_version`}}",
"plan_info": {
    "plan_name": "{{user `image_sku`}}",
    "plan_product": "{{user `image_offer`}}",
    "plan_publisher": "{{user `image_publisher`}}"
},
```
## Pick the image to use
To find the allowed values for the different fields first run `list-publishers`. The list is fairly big so it is advisable to output it into a file that is more easily searchable
```shell
az vm image list-publishers --location westeurope > C:\somelocation\azurepublishers.txt
```
After selecting a publisher, an offer must be selected. The publisher from the previous step is required as an option for the next command.
```shell
az vm image list-offers --location westeurope --publisher "center-for-internet-security-inc" > C:\somelocation\offers.txt
```
Then a sku needs to be selected. The list of allowed skus can be found by running this command
```shell
az vm image list-skus --location westeurope --publisher "center-for-internet-security-inc" --offer "cis-windows-server-2019-v1-0-0-l2" > C:\somelocation\skus.txt
```
To select a specific version to use, the list of versions can be found with this command
```shell
az vm image list --location westeurope --publisher "center-for-internet-security-inc" --offer "cis-windows-server-2019-v1-0-0-l2" --sku "cis-ws2019-l2" --all
```
The filled values look like this
```json
"image_publisher": "center-for-internet-security-inc",
"image_offer": "cis-windows-server-2019-v1-0-0-l2",
"image_sku": "cis-ws2019-l2",
"image_version": "1.0.8",
"plan_info": {
    "plan_name": "cis-ws2019-l2",
    "plan_product": "cis-windows-server-2019-v1-0-0-l2",
    "plan_publisher": "center-for-internet-security-inc"
},
```
**Note:** This template works for Marketplace images in general. For the CIS image in particular there is some additional configuration required to enable WinRM Basic Authentication. If that is not enabled then Packer will provision the VM but will get a WinRM timeout error when it tries to connect. 