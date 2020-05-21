# Packer on Azure with ARM
This repository contains Packer templates that can be used as a starting point for building a VM image on Azure with the Packer azure-arm builder.
If you are new to Packer on Azure and are not sure where to start, refer to the documentation of the basic template [here](basic-template/) and try running it.
The following templates are available:
- [Basic Windows template](basic-template/)
- [Custom Image as base image](image-template/)
- [Azure Marketplace Image as base image](azure-marketplace/)

## Pre-requisites
You need to have an active Azure subscription where have enough rights to provision resources.
You need to have Packer installed.

## Using a template
Packer templates are built with the build command. It is advisable to run a validate command first to check your syntax.
Example:
``` shell
packer validate basic-template.json
```
If validation succeeds run
``` shell
packer build basic-template.json
```
## Azure DevOps Pipeline
I've also included the Azure DevOps pipeline YAML that I use for testing [here](azdo-pipelines/windows-packer-pipeline.yml).