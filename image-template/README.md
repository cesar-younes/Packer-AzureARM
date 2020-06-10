# Custom image as Packer base
This template demonstrates using a custom image as the starting point for the Packer template.
A common use case for this one is having a standard hardened image of an OS that you want to use as the base for all your builds.

# Specifying the Custom Image
To specify the custom image to use the following section needs to be added:
```json
"custom_managed_image_name": "{{user `starting_image_name`}}",
"custom_managed_image_resource_group_name": "{{user `starting_image_rg`}}",
```
If this section is specified then the following **cannot** be included in the template:
- VHD (image_url)
- Image Reference (image_publisher, image_offer, image_sku)
- Shared Image Gallery(shared_image_gallery)