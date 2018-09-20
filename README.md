# Copy-MyAzureVM
A demo PowerShell script to copy Azure virtual machine to anther datacenter.
## Requirements
1. Windows PowerShell 5.0 +
2. Microsoft Azure PowerShell model 5.6.0 +
https://github.com/Azure/azure-powershell/releases
## Limitations
Current version only supports migrate Azure VM between same account, same subscription. 
## Usages
1. Stop Azure VMs on Azure portal, and make sure its staus is 'VM deallocated'
2. Download script file 'Copy-MyAzureVM.ps1' 
3. Open PowerShell console, and run command:
```powershell
## Install Azure PowerShell Module.
PS> Install-Module -Name AzureRM

## Run Copy script.
PS> .\Copy-MyAzureVM.ps1 -SubscriptionId 'xxxxx-9faa-xxxx' -AzureEnvironmentName 'AzureChinaCloud'  -DestLocation 'chinanorth'
PS> 
```
4. Login in your Azure account on popup window.
![Login azure account](https://github.com/mosserlee/Copy-MyAzureVM/blob/master/images/Login-AzureRMAccount.jpg "Login azure account")

5. Select the resource group that your VM located.
![select resource group](https://github.com/mosserlee/Copy-MyAzureVM/blob/master/images/Select-ResourceGroup.png "select resource group")

6. select source virtual machines.
![select source virtual machines](https://github.com/mosserlee/Copy-MyAzureVM/blob/master/images/Select-VM.png "select source virtual machines")
7. Click [OK] to start copy. 

Bellow is the demo output of PowerShell console.
<pre style='background: #012456;color: #EEEDF0;overflow: auto;word-break: normal!important;word-wrap: normal!important;white-space: pre!important;'>
2018-03-29 06:11:34 ::: -Porcess resource group:[DR-DEMO-SH] started...
2018-03-29 06:11:41 ::: --Copy VM [wp-db] started...
2018-03-29 06:11:43 ::: ---Resource group [DR-DEMO-SH-New] does not exist, try to create new one.
2018-03-29 06:11:44 ::: ---Resource group [DR-DEMO-SH-New] create done.
2018-03-29 06:11:50 ::: ---create security group [wp-blog-nsg] started...
2018-03-29 06:12:02 ::: ---create security group [wp-blog-nsg] end
2018-03-29 06:12:05 ::: ---create VNet [DR-DEMO-vnet] started...
2018-03-29 06:12:19 ::: ---create VNet [DR-DEMO-vnet] end.
2018-03-29 06:12:21 ::: ---create network interface [wp-db977] started...
2018-03-29 06:12:23 ::: ---create network interface [wp-db977] done.
2018-03-29 06:12:24 ::: ---add network interface [wp-db977] to security group [wp-blog-nsg] started...
2018-03-29 06:12:25 ::: ---add network interface [wp-db977] to security group [wp-blog-nsg] done.
2018-03-29 06:12:27 ::: ---Storage account [drdemoshnewcopymyazurevm] does not exist, try to create new one.
2018-03-29 06:12:54 ::: ---Storage account [drdemoshnewcopymyazurevm] create done.
2018-03-29 06:12:54 ::: ---Storage container [wp-db] does not exist, try to create new one.
2018-03-29 06:12:54 ::: ---Storage container [wp-db] create done.
2018-03-29 06:12:56 ::: ---Get share access key for disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] started...
2018-03-29 06:13:27 ::: ---Get share access key for disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] ended.
2018-03-29 06:13:27 ::: ---Copy vhd for disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] started...
2018-03-29 06:13:27 ::: ----Copy disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] in progress...
2018-03-29 06:24:49 ::: ----Copy disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] done.
2018-03-29 06:24:49 ::: ----Revoke share access key for disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] started..
.
2018-03-29 06:25:21 ::: ----Revoke share access key for disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] done.
2018-03-29 06:25:21 ::: ---Copy vhd for disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] done.
2018-03-29 06:25:22 ::: ---create disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] started...
2018-03-29 06:25:54 ::: ---create disk [wp-db_OsDisk_1_7775eae21af54cccbef709f9a6a207f6] done.
2018-03-29 06:25:55 ::: ---Get share access key for disk [wp-db-data] started...
2018-03-29 06:26:26 ::: ---Get share access key for disk [wp-db-data] ended.
2018-03-29 06:26:26 ::: ---Copy vhd for disk [wp-db-data] started...
2018-03-29 06:26:27 ::: ----Copy disk [wp-db-data] in progress...
2018-03-29 06:26:58 ::: ----Copy disk [wp-db-data] done.
2018-03-29 06:26:58 ::: ----Revoke share access key for disk [wp-db-data] started...
2018-03-29 06:27:29 ::: ----Revoke share access key for disk [wp-db-data] done.
2018-03-29 06:27:29 ::: ---Copy vhd for disk [wp-db-data] done.
2018-03-29 06:27:30 ::: ---create disk [wp-db-data] started...
2018-03-29 06:28:02 ::: ---create disk [wp-db-data] done.
2018-03-29 06:28:06 ::: ---Create VM [wp-db] started...

RequestId           :
IsSuccessStatusCode : True
StatusCode          : OK
ReasonPhrase        : OK

2018-03-29 06:28:32 ::: ---Create VM [wp-db] done.
2018-03-29 06:28:34 ::: ---Attach disk [wp-db-data] to  VM [wp-db] started...

RequestId           :
IsSuccessStatusCode : True
StatusCode          : OK
ReasonPhrase        : OK

2018-03-29 06:29:06 ::: ---Attach disk [wp-db-data] to  VM [wp-db] done.
2018-03-29 06:29:06 ::: --Copy VM [wp-db] done.
2018-03-29 06:29:06 ::: --Copy VM [wp-site] started...
2018-03-29 06:29:14 ::: ---create public ip [wp-site-ip] started...
2018-03-29 06:29:26 ::: ---create public ip [wp-site-ip] end.
2018-03-29 06:29:27 ::: ---create network interface [wp-site860] started...
2018-03-29 06:29:28 ::: ---create network interface [wp-site860] done.
2018-03-29 06:29:29 ::: ---add network interface [wp-site860] to security group [wp-blog-nsg] started...
2018-03-29 06:29:30 ::: ---add network interface [wp-site860] to security group [wp-blog-nsg] done.
2018-03-29 06:29:31 ::: ---Storage container [wp-site] does not exist, try to create new one.
2018-03-29 06:29:31 ::: ---Storage container [wp-site] create done.
2018-03-29 06:29:32 ::: ---Get share access key for disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] started...
2018-03-29 06:30:03 ::: ---Get share access key for disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] ended.
2018-03-29 06:30:03 ::: ---Copy vhd for disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] started...
2018-03-29 06:30:04 ::: ----Copy disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] in progress...
2018-03-29 06:41:41 ::: ----Copy disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] done.
2018-03-29 06:41:41 ::: ----Revoke share access key for disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] started...
2018-03-29 06:42:13 ::: ----Revoke share access key for disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] done.
2018-03-29 06:42:13 ::: ---Copy vhd for disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] done.
2018-03-29 06:42:14 ::: ---create disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] started...
2018-03-29 06:42:46 ::: ---create disk [wp-site_OsDisk_1_9de19e9aaf484fa88be008f95b6dc403] done.
2018-03-29 06:42:47 ::: ---Get share access key for disk [wp-site-data-1] started...
2018-03-29 06:43:18 ::: ---Get share access key for disk [wp-site-data-1] ended.
2018-03-29 06:43:18 ::: ---Copy vhd for disk [wp-site-data-1] started...
2018-03-29 06:43:19 ::: ----Copy disk [wp-site-data-1] in progress...
2018-03-29 06:52:56 ::: ----Copy disk [wp-site-data-1] done.
2018-03-29 06:52:56 ::: ----Revoke share access key for disk [wp-site-data-1] started...
2018-03-29 06:53:28 ::: ----Revoke share access key for disk [wp-site-data-1] done.
2018-03-29 06:53:28 ::: ---Copy vhd for disk [wp-site-data-1] done.
2018-03-29 06:53:29 ::: ---create disk [wp-site-data-1] started...
2018-03-29 06:54:00 ::: ---create disk [wp-site-data-1] done.
2018-03-29 06:54:04 ::: ---Create VM [wp-site] started...

RequestId           :
IsSuccessStatusCode : True
StatusCode          : OK
ReasonPhrase        : OK

2018-03-29 06:54:40 ::: ---Create VM [wp-site] done.
2018-03-29 06:54:42 ::: ---Attach disk [wp-site-data-1] to  VM [wp-site] started...

RequestId           :
IsSuccessStatusCode : True
StatusCode          : OK
ReasonPhrase        : OK

2018-03-29 06:55:13 ::: ---Attach disk [wp-site-data-1] to  VM [wp-site] done.
2018-03-29 06:55:13 ::: --Copy VM [wp-site] done.
2018-03-29 06:55:13 ::: -Porcess resource group [DR-DEMO-SH] done.
</pre>
