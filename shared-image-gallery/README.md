# Shared Image Gallery Sample
This folder demonstrates working with images in an Azure Shared Image Gallery.
The samples assume the Shared Image Gallery exists. See [the official docs](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries) for steps on how to create one.

If you're wondering why you would need a Shared Image Gallery in the first place, the official docs give a nice description of the benefits:
>Shared Image Gallery is a service that helps you build structure and organization around your managed images. Shared Image Galleries provide:
>- Managed global replication of images.
>- Versioning and grouping of images for easier management.
>- Highly available images with Zone Redundant Storage (ZRS) accounts in regions that support Availability Zones. ZRS offers better resilience against zonal failures.
>- Premium storage support (Premium_LRS).
>- Sharing across subscriptions, and even between Active Directory (AD) tenants, using RBAC.
>- Scaling your deployments with image replicas in each region.

>Using a Shared Image Gallery you can share your images to different users, service principals, or AD groups within your organization. Shared images can be replicated to multiple regions, for quicker scaling of your deployments.


# Storing Images from Shared Image Gallery
To store images in a Shared Image Gallery the following section needs to be added to the Builder section in your Packer template
```json
"shared_image_gallery_destination": {
    "resource_group": "ResourceGroup",
    "gallery_name": "GalleryName",
    "image_name": "ImageName",
    "image_version": "1.0.0",
    "replication_regions": ["regionA", "regionB", "regionC"]
}
```
# Using image in Shared Image Gallery
The following section needs to be added to the Packer template to To use an image in the Shared Image Gallery as the base image for the Packer build.
```json
"shared_image_gallery": {
    "subscription": "{{user `subscription_id`}}",
    "resource_group": "{{user `sig_rg`}}",
    "gallery_name": "{{user `sig_gallery_name`}}",
    "image_name": "{{user `sig_image_name`}}",
    "image_version": "{{user `sig_image_version`}}"
    },
```
If this section is specified then the following **cannot** be included in the template:
- VHD (image_url)
- Image Reference (image_publisher, image_offer, image_sku)
- Managed Disk (custom_managed_disk_image_name, custom_managed_disk_resource_group_name)
- Shared Gallery Image (shared_image_gallery)