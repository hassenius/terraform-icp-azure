# Deploying IBM Cloud Private on Azure using Terraform

These Terraform example templates uses the Terraform AzureRM Provider to provision servers in Azure and [Terraform Module ICP Deploy](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy) to deploy IBM Cloud Private on them.


## Pre-requisits
- Working copy of [Terraform](https://www.terraform.io/intro/getting-started/install.html)
- Basic understanding of [IBM Cloud Private](https://www.ibm.com/cloud/private)
- Azure account
- Access to ICP Images tarball if deploying ICP Enterprise Edition templates

All templates are tested on Ubuntu 16.04 and RHEL.
Details on running RHEL in production [here](docs/rhel.md)


## Available templates

Each template example provided is highly customizable, but are all configured with sensible defaults so they will provide a starting point for the most common use cases.

1. [templates/icp-ce](templates/icp-ce)

   Basic template which deploys a single master node on an azure VM. Both Maser and Proxy are assigned public IP addresses so they can be easily accessed over the internet. IBM Cloud Private Community Edition is installed directly from Docker Hub, so this template does not require access to ICP Enterprise Edition licenses and Image tarball.
   Suitable for initial tests and validations.

2. [templates/icp-ee-az](templates/icp-ee-az)

    Deploy ICP Enterprise Edition in a highly available configuration, with cluster deployed across 3 Azure availability zones

3. [templates/icp-ee-as](templates/icp-ee-as)

    Deploy ICP Enterprise Edition in a highly available configuration, with cluster availability managed using Azure Availability Sets

## Using the templates

1. Select the appropriate [template](templates/) for your use case
2. Adjust it as required, or use one of the sample `terraform.tfvars`
3. Run `terraform init` in the selected template directory
4. Run `terraform apply`

Note: If you are using Terraform v0.12.xx you may get errors saying "Unsupported Argument". To fix this, you'll want to get v0.11.xx (https://releases.hashicorp.com/terraform/0.11.14/) and use that instead.

You will be prompted by the azure provider to login to create a temporary token. To create a permanent service principal which does not time out and require re-authentication, follow these steps outlined in [Terraform docs](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html)

Note: For ICP to work on Azure, the kubernetes controller manager needs to dynamically update the Azure Routing Table. It is therefore essential that the variables `aadClientId` and `aadClientSecret` is populated with a service principal that has permissions to update the azure routing table.


## Using the environments

When the template creation is completed successfully, terraform will produce an output similar to this:
```
Outputs:

ICP Admin Password = 2f052b35d7cdc3c87b5d6b49009fe972
ICP Admin Username = admin
ICP Boot node = 40.67.220.184
ICP Console URL = https://hktestas-f4c95db9-control.westeurope.cloudapp.azure.com:8443
ICP Kubernetes API URL = https://hktestas-f4c95db9-control.westeurope.cloudapp.azure.com:8001
cloudctl = cloudctl login --skip-ssl-validation -a https://hktestas-f4c95db9-control.westeurope.cloudapp.azure.com:8443 -u admin -p 2f052b35d7cdc3c87b5d6b49009fe972 -n default -c id-myicp-account
```

You can use `cloudctl` to configure you local `kubectl` and `helm` command line client to use this environments, and access the Web Console with the provided username and password

For instructions on how to install cloudctl go to the IBM [KnowledgeCenter](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.1/manage_cluster/install_cli.html)

## Azure Network Options and information
You can read more about the Azure network and options in [docs/azure-networking.md](docs/azure-networking.md)

## Using integrated Azure functionality

Depending on your configuration you can use integrated functionality from the Azure Cloud provider for Kubernetes.
Once you have logged in to the environment using `cloudctl` or via `kubectl` authentication information from the dashboard, you can create Azure Load Balancers and Persistent Volumes using `kubectl`

#### Using the Azure Loadbalancer
See details and examples for exposing your workloads with Azure LoadBalancer in [azure-loadbalancer.md](docs/azure-loadbalancer.md)

### Dynamic Volume Provisioning

To be able to dynamically create and attach volumes, we need to create the necessary cluster role and clusterrole binding for the `azure-cloud-provider`

```
kubectl create clusterrole system:azure-cloud-provider --verb=get,create --resource=secrets
kubectl create clusterrolebinding system:azure-cloud-provider --clusterrole=system:azure-cloud-provider --serviceaccount=kube-system:persistent-volume-binder
```
