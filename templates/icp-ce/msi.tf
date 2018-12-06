
# TODO: Limit scope of the identities to the resource group

data "azurerm_subscription" "subscription" {}

data "azurerm_builtin_role_definition" "builtin_role_definition" {
  name = "Reader"
}

# Grant the VM identity contributor rights to the current subscription
# resource "azurerm_role_assignment" "role_assignment" {
#   count              = "${var.master["nodes"]}"
#   scope              = "${data.azurerm_subscription.subscription.id}"
#   role_definition_id = "${data.azurerm_subscription.subscription.id}${data.azurerm_builtin_role_definition.builtin_role_definition.id}"
#   principal_id       = "${element(azurerm_virtual_machine.master.*.identity.0.principal_id, count.index)}"
#
#   lifecycle {
#     ignore_changes = ["name"]
#   }
# }


data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "test" {}


### Maybe tweak this more
# resource "azurerm_role_definition" "worker" {
#   #name               = "icp-workernodes"
#   name               = "${uuid()}"
#   scope              = "${azurerm_resource_group.icp.id}"
#
#   permissions {
#     actions     = ["Microsoft.Compute/virtualMachines/read", "Microsoft.Compute/virtualMachines/*/read"]
#     not_actions = []
#   }
#
#   assignable_scopes = [
#     "${azurerm_resource_group.icp.id}",
#     # "/providers/Microsoft.Compute/virtualMachines"
#   ]
#
#   lifecycle {
#     ignore_changes = ["name"]
#   }
# }



# {
#   "assignableScopes": [
#     "/subscriptions/e2ff6a34-1e5d-46fe-8fac-74cbcd45d42b/resourceGroups/icp_rg"
#   ],
#   "description": "",
#   "id": "/subscriptions/e2ff6a34-1e5d-46fe-8fac-74cbcd45d42b/providers/Microsoft.Authorization/roleDefinitions/295ca204-c019-b76d-7a91-d38c9601a11f",
#   "name": "295ca204-c019-b76d-7a91-d38c9601a11f",
#   "permissions": [
#     {
#       "actions": [
#         "Microsoft.Compute/virtualMachines/read"
#       ],
#       "dataActions": [],
#       "notActions": [],
#       "notDataActions": []
#     }
#   ],
#   "roleName": "icp-workernodes",
#   "roleType": "CustomRole",
#   "type": "Microsoft.Authorization/roleDefinitions"
# },


# resource "azurerm_role_assignment" "workers" {
#   count = "${var.worker["nodes"]}"
#   #name               = "00000000-0000-0000-0000-000000000000"
#   scope              = "${azurerm_resource_group.icp.id}"
#
#   #role_definition_id = "${azurerm_role_definition.worker.id}"
#   role_definition_id  = "${data.azurerm_builtin_role_definition.builtin_role_definition.id}"
#   principal_id       = "${element(azurerm_virtual_machine.worker.*.identity.0.principal_id, count.index)}"
# }
