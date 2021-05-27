{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "vmAdminUsername": {
            "type": "String",
            "metadata": {
                "description": "User name for the Virtual Machine."
            }
        },
        "vmAdminPassword": {
            "type": "SecureString",
            "metadata": {
                "description": "Password for the Virtual Machine."
            }
        },
        "vmName": {
            "type": "String",
            "metadata": {
                "description": "Unique hostname for the Virtual Machine."
            }
        },
        "OSVersion": {
            "defaultValue": "2019-Datacenter",
            "type": "String",
            "metadata": {
                "description": "2019-Datacenter"
            }
        },
        "existingVirtualNetworkResourceGroupName": {
            "type": "String",
            "metadata": {
                "description": "VSTS deployment group name."
            }
        },
        "existingSubnetName": {
            "type": "String",
            "metadata": {
                "description": "Name of the existing subnet in the existing VNET you want to use"
            }
        },
        "existingVirtualNetworkName": {
            "type": "String",
            "metadata": {
                "description": "Name of the existing VNET"
            }
        },
        "vmSize": {
            "defaultValue": "Standard_D2_v3",
            "type": "String",
            "metadata": {
                "description": "Desired Size of the VM. Any valid option accepted but if you choose premium storage type you must choose a DS class VM size."
            }
        },
        "vstsAccount": {
            "defaultValue": "https://dev.azure.com/EnsembleHealth",
            "type": "String",
            "metadata": {
                "description": "Azure devops complete url with organization name."
            }
        },
        "PAT": {
            "defaultValue": "jqavlx4ez3imuriv6qne2s2lr2xkrjtewho6dzrqfhl4mgnfbeea",
            "type": "String",
            "metadata": {
                "description": "Enter PAT token "
            }
        },
        "vstsPoolName": {
            "defaultValue": "Testinfra-dev",
            "type": "String",
            "metadata": {
                "description": "Enter Existing or created Pool name where agent has to be deployed "
            }
        },
        "VstsAgent ": {
            "defaultValue": "EIQagent",
            "type": "String",
            "metadata": {
                "description": "Enter Name of the Agent "
            }
        },
        "AgentNo": {
            "defaultValue": "01",
            "type": "string",
            "metadata": {
                "description": "Enter AgentNo to get Suffix of agent name "
            }
        },
        "resourceTag": {
            "type": "object",
            "metadata": {
                "description": "Tag of AKS resource."
            }
        }
    },
    "variables": {
        "imagePublisher": "MicrosoftWindowsServer",
        "imageOffer": "WindowsServer",
        "nicName": "[concat(parameters('vmName'),'-nic')]",
        "publicIPAddressName": "[concat(parameters('vmName'),'-pip')]",
        "publicIPAddressType": "Dynamic",

        "vnetID": "[resourceId('Microsoft.Network/virtualNetworks',parameters('existingVirtualNetworkName'))]",
        "subnetRef": "[resourceID(parameters('existingVirtualNetworkResourceGroupName'), 'Microsoft.Network/virtualNetWorks/subnets', parameters('existingVirtualNetworkName'), parameters('existingSubnetName'))]"

    },
    "resources": [
        {
            "type": "Microsoft.Network/networkInterfaces",
            "tags": "[parameters('resourceTag')]",
            "apiVersion": "2020-06-01",
            "name": "[variables('nicName')]",
            "location": "[resourceGroup().location]",
            "dependsOn": [
            ],
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "ipconfig1",
                        "properties": {
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[variables('subnetRef')]"
                            }
                        }
                    }
                ]
            }
        },
        {
            "type": "Microsoft.Compute/virtualMachines",
            "apiVersion": "2017-03-30",
            "name": "[parameters('vmName')]",
            "location": "[resourceGroup().location]",
            "dependsOn": [
                "[resourceId('Microsoft.Network/networkInterfaces/', variables('nicName'))]"
            ],
            "properties": {
                "hardwareProfile": {
                    "vmSize": "[parameters('vmSize')]"
                },
                "osProfile": {
                    "computerName": "[parameters('vmName')]",
                    "adminUsername": "[parameters('vmAdminUsername')]",
                    "adminPassword": "[parameters('vmAdminPassword')]"
                },
                "storageProfile": {
                    "imageReference": {
                        "publisher": "[variables('imagePublisher')]",
                        "offer": "[variables('imageOffer')]",
                        "sku": "[parameters('OSVersion')]",
                        "version": "latest"
                    },
                    "osDisk": {
                        "createOption": "FromImage"
                    }
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "id": "[resourceId('Microsoft.Network/networkInterfaces',variables('nicName'))]"
                        }
                    ]
                }
            },
            "resources": [
                {
                    "type": "extensions",
                    "name": "AzureWinAgent",
                    "apiVersion": "2018-06-01",
                    "location": "[ResourceGroup().location]",
                    "dependsOn": [
                        "[concat('Microsoft.Compute/virtualMachines/', parameters('vmName'))]"
                    ],
                    "properties": {
                        "publisher": "Microsoft.Compute",
                        "type": "CustomScriptExtension",
                        "autoUpgradeMinorVersion": true,
                        "typeHandlerVersion": "1.9",
                        "settings": {
                            "fileUris": [
                                "https://rajascript.blob.core.windows.net/hanuscripts/winscript123.ps1"
                            ]
                        },
                        "protectedSettings": {
                            "commandToExecute": "[concat('powershell.exe -ExecutionPolicy Unrestricted -File winscript123.ps1 -vstsAccount ', parameters('vstsAccount'), ' -PAT ', parameters('PAT'), ' -vstsAgent ', parameters('vmName'),' -AgentNo ', parameters('AgentNo'), ' -vstsPoolName ', concat('\"', parameters('vstsPoolName'),'\"'), ' -vmAdminUserName ', parameters('vmAdminUserName'), ' -vmAdminPassword ', parameters('vmAdminPassword'))]"
                        }
                    }
                }
            ]
        }
    ],

    "outputs": {
    }
}
