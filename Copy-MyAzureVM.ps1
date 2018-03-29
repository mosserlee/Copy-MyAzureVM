# Examples:
# .\Copy-MyAzureVM.ps1 -SubscriptionId 'xxxxx-9faa-xxxx' -AzureEnvironmentName 'AzureChinaCloud'  -DestLocation 'chinanorth'
#
########################### Main parameter    ###############################
param(

# Azure subscription Id
[Parameter(Mandatory=$true)]
[string]$SubscriptionId, 

# Azure environment name, for example [AzureChinaCloud],[AzureCloud]
[Parameter(Mandatory=$true)]
[string]$AzureEnvironmentName='AzureCloud',

# Azure datacenter location name, for exampe [chinanorth]
[Parameter(Mandatory=$true)]
[string]$DestLocation,

# Azure account context
[string]$AzureRmContext="$PSScriptRoot\AzureRmContext.json",

# The expiration seconds of Azure managed disk.
[int]$DiskSasDurationInSecond = 3600*24*3,
[string]$LogFile = "$PSScriptRoot\Copy-MyAzureVM-log-{0:yyyy-MM-dd_HH-mm}.log" -f (Get-Date)
)


#
# Resource group transform delegation, you can customize with your logic.
#
[scriptblock]$ResourceGroupTransform = {
    param($sourceRG)
    $sourceRG + "-New"
}

$ErrorActionPreference = 'stop'
$WarningPreference = 'SilentlyContinue'

##############################################################

function Login-MyAzAccount
{
    #$azAccount = ""
    #$azPassword = ""
    #$azCredencial = new-object -typename System.Management.Automation.PSCredential `
    #     -argumentlist $azAccount, (ConvertTo-SecureString –String $azPassword -AsPlainText -Force)
    #     
    #Login-AzAccount -Credential $azCredencial -EnvironmentName AzureChinaCloud

    if(Test-Path $AzureRmContext){
      Import-AzureRmContext -Path $AzureRmContext -Confirm:$false
      if($?){
      return
      }
    }
    Login-AzAccount -EnvironmentName $AzureEnvironmentName
    Set-AzureRmContext -Subscription $SubscriptionId
    Save-AzureRmContext -Path $AzureRmContext -Confirm:$false
}

#
# Start VM copy wizard
#
function Start-MyAzureVMCopyWizard
{
    Login-MyAzAccount
    $rgs = Get-AzureRmResourceGroup | Out-GridView -PassThru -Title "Please select resource groups that your VM located:"
    foreach($rg in $rgs){
        $ResourceGroupName = $rg.ResourceGroupName
        Log-Message "-Porcess resource group:[$ResourceGroupName] started..."

        $vms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName | Out-GridView -PassThru -Title "Please select vm in resource group $ResourceGroupName"
        foreach($vm in $vms)
        {
            Copy-MyVM -VM $vm
        }

        Log-Message "-Porcess resource group [$ResourceGroupName] done."
    }
    if( -not $rgs){
       Log-Message "No any resource groups selected."
    }
}

#
# copy my vm
#
function Copy-MyVM
{
    param($VM)
    Log-Message "--Copy VM [$($VM.Name)] started..."

    #check VM's status
    Check-MyVMStatus -VM $VM

    #create target resource group
    $targetRG = Copy-MyResourceGroup -VM $VM

    # copy security group
    Copy-MySecurityGroup -VM $VM -TargetRG $targetRG

    # copy vnet
    Copy-MyVnet -VM $VM -TargetRG $targetRG

    # copy network interface
    Copy-MyNetworkInterface -VM $VM -TargetRG $targetRG


    # copy disks
    Copy-MyVmDisk -VM $VM -TargetRG $targetRG
    
    # create vm
    New-MyAzureVM -VM $VM -targetRG $targetRG

    #attach data diks
    Attach-MyAzureDataDisk -VM $VM -targetRG $targetRG

    Log-Message "--Copy VM [$($VM.Name)] done."

}
#
# New azure vm
#
function New-MyAzureVM
{
    param(
    $VM,
    $targetRG
    )
    # set name and size
    $vmConfig = New-AzureRmVMConfig -VMName $VM.Name -VMSize $VM.HardwareProfile.VmSize
    # set network interface
    foreach($ni in $VM.NetworkProfile.NetworkInterfaces)
    {
       $vmNI = Get-AzureRmNetworkInterface `
        -ResourceGroupName $TargetRG.ResourceGroupName `
        -Name (Resolve-MyResourceName -Id $ni.Id)
       $vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig `
        -NetworkInterface $vmNI
    }
    # set OS disk
    $isLinux = $VM.OSProfile.LinuxConfiguration -ne $null
    $isWindows = $VM.OSProfile.WindowsConfiguration -ne $null
    $osDisk = Get-AzureRmDisk `
        -ResourceGroupName $TargetRG.ResourceGroupName `
        -DiskName $VM.StorageProfile.OsDisk.Name
    if($isLinux)
    {
       $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig `
         -Linux `
         -ManagedDiskId $osDisk.Id `
         -StorageAccountType StandardLRS `
         -CreateOption Attach ` 
    }
    elseif($isWindows)
        {
       $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig `
         -ManagedDiskId $osDisk.Id `
         -StorageAccountType StandardLRS `
         -CreateOption Attach `
         -Windows
         
    }
    else{
        throw "The source os profile does not been supported in current script."
    }

     
     #create VM
     Log-Message "---Create VM [$($VM.Name)] started..."
     New-AzureRmVM -ResourceGroupName $TargetRG.ResourceGroupName -Location $DestLocation -VM $vmConfig -Confirm:$false
     Log-Message "---Create VM [$($VM.Name)] done."
}

#
# Attach data diks of VM
#
function Attach-MyAzureDataDisk
{
    param(
    $VM,
    $targetRG
    )

    $targetVM = Get-AzureRmVM -ResourceGroupName $TargetRG.ResourceGroupName -Name $VM.Name
     foreach($disk in $VM.StorageProfile.DataDisks)
     {
        $dataDisk = Get-AzureRmDisk -ResourceGroupName $TargetRG.ResourceGroupName -DiskName $disk.Name
        $targetVM = Add-AzureRmVMDataDisk `
            -VM $targetVM `
            -Name $disk.Name `
            -CreateOption Attach `
            -ManagedDiskId $dataDisk.Id `
            -Lun $disk.Lun
     }
     if($VM.StorageProfile.DataDisks.Count -gt 0)
     {
        Log-Message "---Attach disk [$($disk.Name)] to  VM [$($VM.Name)] started..."
        Update-AzureRmVM -VM $targetVM -ResourceGroupName $TargetRG.ResourceGroupName -Confirm:$false
        Log-Message "---Attach disk [$($disk.Name)] to  VM [$($VM.Name)] done."
     }
}

#
# Copy resource group
#
function Copy-MyResourceGroup
{
   param($VM)
   $targetRGName = & $ResourceGroupTransform $VM.ResourceGroupName
   $targetRG = Get-AzureRmResourceGroup -Name $targetRGName  -ErrorAction SilentlyContinue
   if($targetRG){
    return $targetRG
   }
   Log-Message "---Resource group [$targetRGName] does not exist, try to create new one."
   $targetRG = New-AzureRmResourceGroup -Name $targetRGName -Location $DestLocation 
   Log-Message "---Resource group [$targetRGName] create done."
   $targetRG
}

#
# Ensure the source VM is stopped.
#
function Check-MyVMStatus 
{
    param($VM)
    $vmStatus = (Get-AzureRmVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status).Statuses[1].DisplayStatus
    if($vmStatus -ne 'VM deallocated'){
        throw "Please stop your vm [$($VM.Name)] firstly, and ensure its status is [VM deallocated]"
    }
}

#
# Copy disk
#
function Copy-MyVmDisk
{
   param($VM,$TargetRG)

   # create storage account
   $storageAccountName = Get-MyDestStorageAccountName -TargetRG $TargetRG.ResourceGroupName
   $targetStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $TargetRG.ResourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue
   if($targetStorageAccount -eq $null){
    Log-Message "---Storage account [$storageAccountName] does not exist, try to create new one."
    $targetStorageAccount = New-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $TargetRG.ResourceGroupName -Location $TargetRG.Location -SkuName 'Standard_LRS'
    Log-Message "---Storage account [$storageAccountName] create done."
   }
   $storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName  $TargetRG.ResourceGroupName -Name $storageAccountName | select -First 1 -ExpandProperty value
   $targetStorageContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -Environment $AzureEnvironmentName

   ## create containner
   $targetContainerName = $VM.Name
   $targetContainer = Get-AzureStorageContainer -Context $targetStorageContext -Name $targetContainerName -ErrorAction SilentlyContinue
   if($targetContainer -eq $null){
     Log-Message "---Storage container [$targetContainerName] does not exist, try to create new one."
     $targetContainer = New-AzureStorageContainer -Context $targetStorageContext -Name $targetContainerName -Permission Container
     Log-Message "---Storage container [$targetContainerName] create done."
   }
   
  
   # copy disks
   $disks = New-Object System.Collections.ArrayList($null)
   $disks.Add($VM.StorageProfile.OsDisk) | Out-Null
   $disks.AddRange($VM.StorageProfile.DataDisks)

   foreach($disk in $disks)
   {
     $targetDisk = Get-AzureRmDisk `
        -ResourceGroupName  $TargetRG.ResourceGroupName `
        -Name $disk.Name `
        -ErrorAction SilentlyContinue
      if($targetDisk -ne $null){
            continue
        }

     # Copy disk to destnation storage account
     Log-Message "---Get share access key for disk [$($disk.Name)] started..."
     $sas = Grant-AzureRmDiskAccess -ResourceGroupName $VM.ResourceGroupName -DiskName $disk.Name -Access Read -DurationInSecond $DiskSasDurationInSecond -Confirm:$false
     Log-Message "---Get share access key for disk [$($disk.Name)] ended."
     
     Log-Message "---Copy vhd for disk [$($disk.Name)] started..."
     $targetVHDName = "{0}.VHD" -f $disk.Name
     Start-AzureStorageBlobCopy `
        -AbsoluteUri $sas.AccessSAS `
        -DestContainer $targetContainerName `
        -DestContext $targetStorageContext `
        -DestBlob $targetVHDName `
        -Confirm:$false -Force | 
        Out-Null

     Log-Message "----Copy disk [$($disk.Name)] in progress..."
     Get-AzureStorageBlobCopyState `
         -Context $targetStorageContext `
         -Container $targetContainerName `
         -Blob $targetVHDName -WaitForComplete | 
         Out-Null
     Log-Message "----Copy disk [$($disk.Name)] done."
     
     Log-Message "----Revoke share access key for disk [$($disk.Name)] started..."
     Revoke-AzureRmDiskAccess `
         -ResourceGroupName $VM.ResourceGroupName `
         -DiskName $disk.Name `
         -Confirm:$false |
         Out-Null
     Log-Message "----Revoke share access key for disk [$($disk.Name)] done."
     
     Log-Message "---Copy vhd for disk [$($disk.Name)] done."
     
     # create disk by VHD file
     $vhdUrl = "https://{0}.blob.{1}/{2}/{3}.VHD" -f `
     $storageAccountName,
     (Get-AzureRmEnvironment -Name $AzureEnvironmentName).StorageEndpointSuffix,
     $VM.Name,
     $disk.name
     
     $sourceDiskObj = Get-AzureRmDisk -DiskName $disk.Name  -ResourceGroupName $VM.ResourceGroupName
     
     Log-Message "---create disk [$($disk.Name)] started..."
     $diskCfg = New-AzureRmDiskConfig `
        -Location $DestLocation `
        -CreateOption Import `
        -SourceUri $vhdUrl `
        -SkuName $sourceDiskObj.Sku.Name `
        -Confirm:$false
     $targetDisk = New-AzureRmDisk `
        -ResourceGroupName $TargetRG.ResourceGroupName  `
        -DiskName $disk.name `
        -Disk $diskCfg `
        -Confirm:$false 
     Log-Message "---create disk [$($disk.Name)] done."
   }

}

#
# Copy vnet
#
function Copy-MyVnet
{
    param($VM,$TargetRG)

    $vnets = Get-AzureRmVirtualNetwork -ResourceGroupName $VM.ResourceGroupName
    foreach($vnet in $vnets){
        
        #copy vnet
        $targetVnet = Get-AzureRmVirtualNetwork -ResourceGroupName $TargetRG.ResourceGroupName -Name $vnet.Name -ErrorAction SilentlyContinue
        if($targetVnet -eq $null){
            Log-Message "---create VNet [$($vnet.Name)] started..."
            $vnetsubConfigs=New-Object System.Collections.ArrayList($null)
            # copy child net
            foreach($subNet in ($vnet | Get-AzureRmVirtualNetworkSubnetConfig)){
                $subIpConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subNet.Name -AddressPrefix $subNet.AddressPrefix
                $vnetsubConfigs.Add($subIpConfig) | Out-Null
            }
            $targetVnet = New-AzureRmVirtualNetwork -Name $vnet.Name `
             -ResourceGroupName $TargetRG.ResourceGroupName `
             -Location $DestLocation `
             -AddressPrefix $vnet.AddressSpace.AddressPrefixes `
             -Subnet $vnetsubConfigs `
             -Confirm:$false 
            Log-Message "---create VNet [$($vnet.Name)] end."
        }
        
    }
    
}

#
# Copy security group
#
function Copy-MySecurityGroup
{
    param($VM,$TargetRG)
    foreach($sg in (Get-AzureRmNetworkSecurityGroup -ResourceGroupName $VM.ResourceGroupName)){
        $targetSG = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $TargetRG.ResourceGroupName -Name $sg.Name -ErrorAction SilentlyContinue
        if($targetSG -eq $null){
            $sgRules = New-Object System.Collections.ArrayList($null)
            foreach($rule in ($sg| Get-AzureRmNetworkSecurityRuleConfig)){
                $newRule =  New-AzureRmNetworkSecurityRuleConfig -Name $rule.Name `
                -SourcePortRange $rule.SourcePortRange `
                -SourceAddressPrefix $rule.SourceAddressPrefix `
                -DestinationPortRange $rule.DestinationPortRange `
                -DestinationAddressPrefix $rule.DestinationAddressPrefix `
                -Priority $rule.Priority `
                -Protocol $rule.Protocol `
                -Access $rule.Access `
                -Direction $rule.Direction 
                $sgRules.Add($newRule) | Out-Null

            }
            Log-Message "---create security group [$($sg.Name)] started..."
            $targetSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $TargetRG.ResourceGroupName `
            -Name $sg.Name `
            -Location $DestLocation `
            -SecurityRules $sgRules `
            -Confirm:$false
            Log-Message "---create security group [$($sg.Name)] end"

        }
    }
}

#
# Copy network interface
#
function Copy-MyNetworkInterface
{
 param($VM,$TargetRG)
 foreach($ni in $VM.NetworkProfile.NetworkInterfaces)
 {
    $niName = Resolve-MyResourceName -Id $ni.id
    $newNiObj = Get-AzureRmNetworkInterface -Name $niName -ResourceGroupName $TargetRG.ResourceGroupName -ErrorAction SilentlyContinue
    if($newNiObj) {
        continue
    }

    $niObj = Get-AzureRmNetworkInterface -Name $niName -ResourceGroupName $VM.ResourceGroupName
    $ipConfigurations = New-Object System.Collections.ArrayList($null)
    foreach($ip in $niObj.IpConfigurations)
    {
        # create public ip
        $pubIpId = $null
        if($ip.PublicIpAddress -ne $null){
            $pubIpName = Resolve-MyResourceName -Id $ip.PublicIpAddress.Id 
            $pubIp = Get-AzureRmPublicIpAddress -ResourceGroupName $VM.ResourceGroupName -Name $pubIpName
            $newPubIp = Get-AzureRmPublicIpAddress -ResourceGroupName $TargetRG.ResourceGroupName `
             -Name $pubIpName -ErrorAction SilentlyContinue
            if($newPubIp -eq $null){

                Log-Message "---create public ip [$pubIpName] started..."
                $newPubIp = New-AzureRmPublicIpAddress `
                -ResourceGroupName $TargetRG.ResourceGroupName `
                -Name $pubIpName -AllocationMethod Dynamic `
                -Location $DestLocation `
                -Confirm:$false
                Log-Message "---create public ip [$pubIpName] end."
            }
            $newPubIp = Get-AzureRmPublicIpAddress `
                -ResourceGroupName $TargetRG.ResourceGroupName `
                -Name $pubIpName 
            $pubIpId = Resolve-MyResourceId `
             -Id $newPubIp.Id `
             -ResourceGroupName $TargetRG.ResourceGroupName

        }

        # create ip config
        $subIpId = Resolve-MyResourceId -Id $ip.Subnet.Id -ResourceGroupName $TargetRG.ResourceGroupName
        $newIP=New-AzureRmNetworkInterfaceIpConfig `
        -Name $ip.Name `
        -PrivateIpAddress $ip.PrivateIpAddress `
        -PrivateIpAddressVersion $ip.PrivateIpAddressVersion `
        -SubnetId $subIpId `
        -PublicIpAddressId $pubIpId  `
        
        $ipConfigurations.Add($newIP) | Out-Null
    }

    # create network interface
    Log-Message "---create network interface [$niName] started..."
    $newNI = New-AzureRmNetworkInterface `
        -ResourceGroupName $TargetRG.ResourceGroupName `
        -Name $niName `
        -Location $DestLocation `
        -IpConfiguration $ipConfigurations `
        -Confirm:$false
    Log-Message "---create network interface [$niName] done."


    $newNI = Get-AzureRmNetworkInterface -Name $niName -ResourceGroupName $TargetRG.ResourceGroupName

    # Set security group for network interface
    if($niObj.NetworkSecurityGroup -ne $null){
        $sgName = Resolve-MyResourceName -Id $niObj.NetworkSecurityGroup.Id
        $targetSG = Get-AzureRmNetworkSecurityGroup `
         -ResourceGroupName $TargetRG.ResourceGroupName `
         -Name $sgName
        Log-Message "---add network interface [$niName] to security group [$sgName] started..."
        $newNI.NetworkSecurityGroup = $targetSG
        $newNI = Set-AzureRmNetworkInterface -NetworkInterface $newNI
        Log-Message "---add network interface [$niName] to security group [$sgName] done."
    }
          
 }
}

#
# Resolve my reource name
#
function Resolve-MyResourceName
{
    param($Id)
    $Id -split '/' | select -Last 1
}

#
# Resolve resource id from source resource group to destination group.
#
function Resolve-MyResourceId
{
    param($Id,$ResourceGroupName)
    $idToken = $Id -split '/'
    $idToken[4] = $ResourceGroupName
    $idToken -join '/'
}

#
# Get destination storage account name 
#
function Get-MyDestStorageAccountName
{
    param($TargetRG)
    $storageAccountName = ("{0}CopyMyAzureVMHub" -f $TargetRG).Replace("-","").Replace("-","")
    if($storageAccountName.Length -gt 24)
    {
        return $storageAccountName.Substring(0,24).ToLower()
    }
    return $storageAccountName.ToLower()
}

#
# Log message 
#
function Log-Message ($Msg)
{
    $msgBody = "{0:yyyy-MM-dd HH:mm:ss} ::: {1}" -f (Get-Date),$Msg
    Write-Host $msgBody
    $msgBody | Out-File $LogFile -Append

}


#
# Start azure vm copy wizard.
#
Start-MyAzureVMCopyWizard 