# If you like to run this script directly from powershell, you have to use the param section instead of parsing the trigger input from json
#param(
#    [parameter(Mandatory=$true)]
#	[String] $deploymentName = "Name of the deployment and domain name prefix",
#    [parameter(Mandatory=$true)]
#	[String] $emailTOAddress = "Client's email address which will be used for notification when the deployment is complete",
#    [parameter(Mandatory=$true)]
#	[String] $emailCCAddress = "CC email address which will be used for notification when the deployment is complete",
#    [parameter(Mandatory=$true)]
#	[String] $emailBody = "This is what the customer entered as a message to us in the web form",
#    [parameter(Mandatory=$true)]
#	[String] $customerName = "Name of the customer, as entered in the web form"
#)
$in = Get-Content $triggerInput -Raw | ConvertFrom-Json
Write-Output "PowerShell script processed queue message '$in'"

$deploymentName = $in.deploymentName
Write-Output $deploymentName
$emailTOAddress = $in.emailTOAddress
Write-Output $emailTOAddress
$emailCCAddress = $in.emailCCAddress
Write-Output $emailCCAddress
$emailBody = $in.emailBody
Write-Output $emailBody
$customerName = $in.customerName
Write-Output $customerName

Import-Module Azure

###### Important variables, please fill in YOUR values here
# location of the deployment
$location = "northeurope"
# vm size, replace as needed with your requirements
$vmSize = "Standard_DS11_v2"
# the following two settings need to point to urls where the script can copy the original operating disk vhd and optionally a data disk vhd from. These links need to be either pointing
# to a public blob or you can also use a SAS url to a blob. You may generate the SAS urls using any storage tool, for example with Microsoft Storage Explorer (http://www.storageexplorer.com)
$sourceVhd = "LINK_TO_SOURCE_OPERATING_DISK_VHD_GOES_HERE"
$sourceDataDiskVhd = "LINK_TO_SOURCE_DATA_DISK_VHD_GOES_HERE (OPTIONAL)" # set to "" if you don't need a data disk clone
# to send the notification emails, you need to fill in the smtp settings here
$smtpServer = "YOUR_SMTP_SERVER_FQDN"
$senderAddress = "TEST <test@test.com>";
$smtpUser = "SMTP_USERNAME"
$smtpPassword = "SMTP_PASSWORD"
# Azure service principal information. Please check "CreateServicePrincipal.ps1" to get the neccessary credentials generated in YOUR Azure subscription.
# If you like to know more about how to create a service principal in Azure, please check https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal
$servicePrincipalPassword = "SERVICE_PRINCIPAL_PASSWORD"
$applicationId = "SERVICE_PRINCIPAL_APPLIACTION_ID"
$tenantId = "SERVICE_PRINCIPAL_TENANT_ID"

$resourceGroupName = $deploymentName + "-rg"
$vnetName = $deploymentName + "-vnet"
$ipName = $deploymentName + "-ip"
$domName = $deploymentName + "-dom"
$nicName = $deploymentName + "-nic"
$vmName = $deploymentName + "-vm"
$diskName = $deploymentName + "-osdisk"
$storageAccountName = $deploymentName + "storage"
$destinationVhdName = "osdisk.vhd"
$destinationDataDiskVhdName = "datadisk.vhd"
$nsgName = $deploymentName + "-nsg"

#generate eMail Credentials
$SecurePassword = $smtpPassword | ConvertTo-SecureString -AsPlainText -Force 
$Credentials = New-Object System.Management.Automation.PSCredential `
     -ArgumentList $smtpUser, $SecurePassword 

## Initial eMail
$emailBody = "<html><body><h1>A new virtual machine was ordered by: " + $customerName + "</h1><p>Customer's Note: "+$emailBody+"</p></body></html>"
Send-MailMessage -to $emailTOAddress -Cc $emailCCAddress -BodyAsHtml -from $senderAddress -Subject "A new virtual machine was ordered" -body $emailBody -SmtpServer $smtpServer -UseSsl -Credential $Credentials -encoding ([System.Text.Encoding]::UTF8)

# Login to Azure with Service Principal
$secpasswd = ConvertTo-SecureString $servicePrincipalPassword -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($applicationId, $secpasswd)
Login-AzureRmAccount -ServicePrincipal -Tenant $tenantId -Credential $mycreds

# Create the resource group
New-AzureRmResourceGroup -Location $location -Name $resourceGroupName

# Create Storage Account for disks
$destStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Location $location -Name $storageAccountName -Kind Storage -SkuName Premium_LRS
$destStorageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName

### Create the destination context for authenticating the copy
$destContext = New-AzureStorageContext  –StorageAccountName $storageAccountName `
                                        -StorageAccountKey $destStorageAccountKey[0].Value  

### Target Container Name
$containerName = "vhds"
 
### Create the target container in storage
New-AzureStorageContainer -Name $containerName -Context $destContext 
 
### Start the Asynchronous Copy ###
$blob1 = Start-AzureStorageBlobCopy -srcUri $sourceVhd `
                                    -DestContainer $containerName `
                                    -DestBlob $destinationVhdName `
                                    -DestContext $destContext

if($sourceDataDiskVhd -ne "")
{
	$blob2 = Start-AzureStorageBlobCopy -srcUri $sourceDataDiskVhd `
										-DestContainer $containerName `
										-DestBlob $destinationDataDiskVhdName `
										-DestContext $destContext
}


### Retrieve the current status of the copy operation ###
$status = Get-AzureStorageBlobCopyState -Context $destContext -Container $containerName -Blob $destinationVhdName 
 
### Print out status ### 
$status 
 
### Loop until complete ###                                    
While($status.Status -eq "Pending"){
  $status = Get-AzureStorageBlobCopyState -Context $destContext -Container $containerName -Blob $destinationVhdName 
  Start-Sleep 10
  ### Print out status ###
  $status
}
$destinationVhd = $blob1.ICloudBlob.Uri

if($sourceDataDiskVhd -ne "")
{
	### Wait also for copy job of data disk to complete
	### Retrieve the current status of the copy operation ###
	$status = Get-AzureStorageBlobCopyState -Context $destContext -Container $containerName -Blob $destinationDataDiskVhdName 
 
	### Print out status ### 
	$status 
 
	### Loop until complete ###                                    
	While($status.Status -eq "Pending"){
	  $status = Get-AzureStorageBlobCopyState -Context $destContext -Container $containerName -Blob $destinationDataDiskVhdName 
	  Start-Sleep 10
	  ### Print out status ###
	  $status
	}

	$destinationDataDiskVhd = $blob2.ICloudBlob.Uri
}

# Create the VNET
$vnetDef = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix '10.0.0.0/16'
$vnet = $vnetDef | Add-AzureRmVirtualNetworkSubnetConfig -Name 'Subnet-1' -AddressPrefix '10.0.0.0/24' | Set-AzureRmVirtualNetwork

# Create Network Security Group with Rules

# sample firewall rules, use what you need and add the reference to the security group creation command below at the end of the line (see commented out sample rules)
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
#$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP1" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 11080
#$rule3 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP2" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 15080
#$rule4 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP3" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 19080
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName -SecurityRules $rule1 #,$rule2,$rule3,$rule4

# Create the NIC
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -Name $ipName -DomainNameLabel $domName -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -PublicIpAddressId $pip.Id -SubnetId $vnet.Subnets[0].Id -NetworkSecurityGroupId $nsg.Id

# Create the VM Config
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $diskName -VhdUri $destinationVhd `
                                -CreateOption Attach -Windows

if($sourceDataDiskVhd -ne "")
{
	$vmConfig = Add-AzureRmVMDataDisk -VM $vmConfig -Name 'DataDisk1' -Caching ReadOnly -CreateOption Attach -VhdUri $destinationDataDiskVhd -Lun 0 -DiskSizeInGB 50
}

$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Finally create the VM
$vm = New-AzureRmVM -VM $vmConfig -Location $location -ResourceGroupName $resourceGroupName

## Finalization eMail with server address
$emailBody = "<html><body><h1>Your virtual machine is ready here: " + $pip.DnsSettings.Fqdn + "</h1></body></html>"
Send-MailMessage -to $emailTOAddress -Cc $emailCCAddress -BodyAsHtml -from $senderAddress -Subject "Your virtual machine is ready" -body $emailBody -SmtpServer $smtpServer -UseSsl -Credential $Credentials -encoding ([System.Text.Encoding]::UTF8)
