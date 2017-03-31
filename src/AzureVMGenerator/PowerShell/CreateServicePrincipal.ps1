$appName = "Service Principal Vm Generator $($userName)"
$dummyUrl = "http://some-domain.com/whatever"

$bytes = New-Object Byte[] 32
$rand = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rand.GetBytes($bytes)

$ClientSecret = [System.Convert]::ToBase64String($bytes)
Write-Output "Service Principal Password: " $ClientSecret

$endDate = [System.DateTime]::Now.AddYears(2)

$azureAdApplication = New-AzureRmADApplication -DisplayName $appName -HomePage $dummyUrl -IdentifierUris $dummyUrl -Password $ClientSecret -EndDate $endDate

Write-Output "Application-Id: " $azureAdApplication.ApplicationId

New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId

Write-Output "Waiting 30 Seconds for the Service Principal to be created"
Start-Sleep -Seconds 30

New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $azureAdApplication.ApplicationId