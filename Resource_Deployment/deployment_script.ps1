# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

#login to azure 
Write-Host "Login to Azure"
az login 


#set parameters 
$subscriptionId = Read-Host "subscription Id"
$resource_group = Read-Host "resource group name"
$resource_name = Read-Host "unique name"
$synapseUser = Read-Host "username for Azure Synapse" 
$password = Read-Host "password for Azure Synapse"
$synapsepassword = ConvertTo-SecureString $password -AsPlainText -Force
$user = New-Object System.Management.Automation.PSCredential ($synapseUser, $synapsepassword)
$location = Read-Host "location"

Write-Host "creating resource group"
az group create --location $location --name $resource_group --subscription $subscriptionId 

$workspace_name = $resource_name + "ws"
$storage_account = $resource_name + "storage"
$file_system = $resource_name + "container"

Write-Host "creating data lake storage account"
az storage account create --name $storage_account --resource-group $resource_group --enable-hierarchical-namespace true

Write-Host "creating container in storage account"
az storage container create --name $file_system --account-name $storage_account

Write-Host "installing the Azure CLI for Azure Synapse"
Install-Module -Name Az.Synapse -RequiredVersion 0.1.0
Import-Module Az.Synapse

Write-Host "creating synapse workspace" 
az synapse workspace create --resource-group $resource_group `
                            --name $workspace_name --location $location `
                            --file-system $file_system --sql-admin-login-user $synapseUser `
                            --sql-admin-login-password $password `
                            --storage-account $storage_account

$spark_pool = $resource_name + "sp"
 
Write-Host "creating Spark pool"
az synapse spark pool create --name $spark_pool `
                            --node-count 3 `
                            --node-size Medium `
                            --resource-group $resource_group `
                            --spark-version 2.4 `
                            --workspace-name $workspace_name `
                            --enable-auto-pause true `
                            --min-node-count 0 `
                            --max-node-count 3

$sql_pool = $resource_name + "sql"
Write-Host "creating SQL pool"
az synapse sql pool create --name $sql_pool --performance-level "DW100c" \
--workspace-name $workspace_name --resource-group $resource_group

#adding Tag
az deployment group create --resource-group $resource_group --subscription $subscriptionId  --template-file .\azuredeploy.json