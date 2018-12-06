# TODO: Create storage account for azure-disk type:shared
# Use the storage account to pupulate this:
# kind: StorageClass
# apiVersion: storage.k8s.io/v1
# metadata:
#   name: slow
# provisioner: kubernetes.io/azure-disk
# parameters:
#   skuName: Standard_LRS
#   location: eastus
#   storageAccount: azure_storage_account_name
