
# Terraform templates for Deploying IBM Cloud Private on Azure

We have a collection of templates that can stand up a ICP environment in Azure Infrastructure with minimal input.

## Selecting the right template

We currently have two templates available

- [icp-ce](icp-ce)
  * This template will deploy ICP Community Edition with a minimal amount of Virtual Machines and a minimal amount of services enabled
  * This template is suitable for a quick view of basic ICP and Kubernetes functionality, and simple PoCs and verifications

- [icp-ee-az](icp-ee-az)
  * This template deploys ICP Enterprise Edition across three Azure Availability Zones.
  * This configuration requires access to ICP Enterprise Edition, typically supplied as a tarball

- [icp-ee-as](icp-ee-as)
  * This template deploys ICP Enterprise Edition in a single Azure Data Centre, but with availability managed by Azure Availability Sets.
  * This configuration requires access to ICP Enterprise Edition, typically supplied as a tarball


Follow the link to these templates for more detailed information about them.
