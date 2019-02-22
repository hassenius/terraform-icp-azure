## Load Balancer
To expose an application with Azure Load balancer, follow these steps

1. Create a new deployment of nginx as a sample application to expose
   ```
   kubectl run mynginx --image=nginx --replicas=2 --port=80
   ```
   Note: If you get a imagepolicy error you'll need to whitelist images from docker hub
   See IBM [KnowledgeCenter](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.2/manage_images/image_security.html) for information on how to do this

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


## Multiple ports from same POD / external-ip
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

## Internal Loadbalancer
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

When creating LoadBalancer service types, all non-master nodes are added to the back-end loadbalancer pool by the Kubernetes Azure Cloud Provider. However, node types such as management, vulnerability advisor, proxy, etc, may have security groups different from the worker nodes, which would block some of the incoming traffic from the load balancer. To avoid this you will need to exclude these node types from the loadbalancer manually as of ICP 3.1.2
To exclude non worker nodes from the loadbalancer, run the following command

```
kubectl label node -l node-role.kubernetes.io/worker!=true,node-role.kubernetes.io/master!=true  alpha.service-controller.kubernetes.io/exclude-balancer=true
```
