# Deploying IBM Cloud Private on Azure using TerraForm

These TerraForm example templates uses the Terraform AzureRM Provider to provision servers in Azure and [Terraform Module ICP Deploy](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy) to deploy IBM Cloud Private on them.


## Pre-requisits
- Working copy of [Terraform](https://www.terraform.io/intro/getting-started/install.html)
- Basic understanding of [IBM Cloud Private](https://www.ibm.com/cloud/private)
- Azure account
- Access to ICP Images tarball if deploying ICP Enterprise Edition templates


## Available templates

Each template example provided is highly customizable, but are all configured with sensible defaults so they will provide a starting point for the most common use cases.

1. [templates/icp-ce](templates/icp-ce)

   Basic template which deploys a single master node on an azure VM. Both Maser and Proxy are assigned public IP addresses so they can be easily accessed over the internet. IBM Cloud Private Community Edition is installed directly from Docker Hub, so this template does not require access to ICP Enterprise Edition licenses and Image tarball.
   Suitable for initial tests, and validations.

2. [templates/icp-ee](templates/)

    Comming soon.
    Deploy ICP Enterprise Edition in a highly available configuration.
