# Deploying IBM Cloud Private on Azure using Terraform

These Terraform example templates uses the Terraform AzureRM Provider to provision servers in Azure and [Terraform Module ICP Deploy](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy) to deploy IBM Cloud Private on them.


## Pre-requisits
- Working copy of [Terraform](https://www.terraform.io/intro/getting-started/install.html)
- Basic understanding of [IBM Cloud Private](https://www.ibm.com/cloud/private)
- Azure account
- Access to ICP Images tarball if deploying ICP Enterprise Edition templates

All templates are tested on Ubuntu 16.04


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

## Using integrated Azure functionality

Depending on your configuration you can use integrated functionality from the Azure Cloud provider for Kubernetes.
Once you have logged in to the environment using `cloudctl` or via `kubectl` authentication information from the dashboard, you can create Azure Load Balancers and Persistent Volumes using `kubectl`

### Load Balancer
To expose an application with Azure Load balancer, follow these steps

1. Create a new deployment of nginx as a sample application to expose
   ```
   kubectl run mynginx --image=nginx --replicas=2 --port=80
   ```
   Note: If you get a imagepolicy error you'll need to whitelist images from docker hub
   See IBM [KnowledgeCenter](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.1/manage_images/image_security.html) for information on how to do this
2. Expose the deployment with type LoadBalancer
    ```
    kubectl expose deployment mynginx --port=80 --type=LoadBalancer
    ```
4. After a few minutes the load balancer will be available and you can see the IP address of the loadbalancer
    ```
    $ kubectl get services
    NAME         TYPE           CLUSTER-IP   EXTERNAL-IP      PORT(S)        AGE
    kubernetes   ClusterIP      10.1.0.1     <none>           443/TCP        12h
    mynginx      LoadBalancer   10.1.0.220   51.145.183.111   80:30432/TCP   2m
    ```
5. Connect to this IP address with your web browser or `curl` to validate that you see the nginx welcome message.


#### Multiple ports from same POD / external-ip
To expose multiple ports from the same POD though a load balancer, you duplicate the port field in your POD spec and Service Spec. For example

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-multiport-deployment
spec:
  selector:
    matchLabels:
      app: multiport
  replicas:
  template:
    metadata:
      labels:
        app: multiport
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
          name: http
        - containerPort: 443
          name: https
---
kind: Service
apiVersion: v1
metadata:
  name: multiport
spec:
  selector:
    app: multiport
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    name: http
  - protocol: TCP
    port: 443
    targetPort: 443
    name: https
```

Will produce a result like this where port 80 and 443 is accessible through the loadbalancer.

```
14:34 $ kubectl get svc
NAME         TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)                      AGE
kubernetes   ClusterIP      10.1.0.1     <none>          443/TCP                      6h
multiport    LoadBalancer   10.1.0.202   40.67.158.141   80:31658/TCP,443:31449/TCP   15m
```

#### Internal Loadbalancer
To provision an internal loadbalancer which uses IP addresses from the internal Vnet rather than external network, add the `service.beta.kubernetes.io/azure-load-balancer-internal: "true"` to the request, so for example

```
kind: Service
apiVersion: v1
metadata:
  name: internal
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  selector:
    app: multiport
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    name: http
  - protocol: TCP
    port: 443
    targetPort: 443
    name: https
```

Will return a result similar to this

```
NAME         TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)                      AGE
internal     LoadBalancer   10.1.0.79    10.0.128.4      80:31327/TCP,443:30229/TCP   3m
kubernetes   ClusterIP      10.1.0.1     <none>          443/TCP                      6h
```


## Known issues and limitations

### Load balancers
When creating LoadBalancer service types, all non-master nodes are added to the back-end loadbalancer pool by the Kubernetes Azure Cloud Provider. However, node types such as management, vulnerability advisor, proxy, etc, may have security groups different from the worker nodes, which would block some of the incoming traffic from the load balancer. To avoid this you will need to exclude these node types from the loadbalancer manually as of ICP 3.1.2
To exclude non worker nodes from the loadbalancer, run the following command

```
kubectl label node -l node-role.kubernetes.io/worker!=true,node-role.kubernetes.io/master!=true  alpha.service-controller.kubernetes.io/exclude-balancer=true
```

### Dynamic Volume Provisioning

To be able to dynamically create and attach volumes, we need to create the necessary cluster role and clusterrole binding for the `azure-cloud-provider`

```
kubectl create clusterrole system:azure-cloud-provider --verb=get,create --resource=secrets
kubectl create clusterrolebinding system:azure-cloud-provider --clusterrole=system:azure-cloud-provider --serviceaccount=kube-system:persistent-volume-binder
```
