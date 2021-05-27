#### CHECK AZURE DEVOPS DEPLOYMENT GROUP PRESENT OR NOT

$user = $null
$deploymentGroupName = "test1234"
$token = "5mbftpk77acye5l7ylzknciytx5xx6iy2p35scr5wkiboxqmcwrq"
$poolName = 'EIQ-Test123'

#$poolId = .\TryCreateDeploymentPool -Name $poolName

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))
$headers = @{ Authorization = ("Basic {0}" -f "$base64AuthInfo") }
$url = "https://dev.azure.com/EnsembleHealth/EIQ/_apis/distributedtask/deploymentgroups?api-version=6.0-preview.1"

$response = Invoke-RestMethod $url -Headers $headers -Method Get -Verbose
$json = ConvertTo-Json $response.value

write-host "Output: $json"

[Array] $result = $response.value | Where-Object { $_.name -eq $deploymentGroupName }

$json = ConvertTo-Json $result
$json
write-host "Filter: $json"

if($result.Length -eq 1)

{
    Write-Host "Deployment Group $deploymentGroupName exists"
}
else
{
    #Create the deployment group

   Write-Host "Deployment Group $deploymentGroupName doesn't exist... Creating"
}