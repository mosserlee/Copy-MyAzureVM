# Copy-MyAzureVM
A demo PowerShell script to copy Azure virtual machine to anther datacenter.
## Requirements
1. Windows PowerShell 5.0 +
2. Microsoft Azure PowerShell model 5.6.0 +
https://github.com/Azure/azure-powershell/releases

## Usages
1. Stop Azure VMs on Azure portal, and make sure its staus is 'VM deallocated'
2. Download script file 'Copy-MyAzureVM.ps1' 
3. Open PowerShell console, and run command:
```powershell
PS> .\Copy-MyAzureVM.ps1 -SubscriptionId 'xxxxx-9faa-xxxx' -AzureEnvironmentName 'AzureChinaCloud'  -DestLocation 'chinanorth'
PS> 
```
The script will guide you to login in with your Azure account, and select target resource groups, and virtual machines.
