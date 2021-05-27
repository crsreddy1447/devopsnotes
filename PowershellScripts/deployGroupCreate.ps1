#https://www.cloudsma.com/2019/05/building-json-payload-in-powershell/

Param
(
    [string] $DeploymentGroup,
    [string] $Description,
    [string] $Token
)
$user = $null
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $Token)))
$headers = @{ Authorization = ("Basic {0}" -f "$base64AuthInfo") }
$url = "https://dev.azure.com/EnsembleHealth/EIQ/_apis/distributedtask/deploymentGroups?api-version=6.0-preview.1"
$response = Invoke-RestMethod $url -Headers $headers -Method Get -Verbose
$json = ConvertTo-Json $response.value
[Array] $result = $response.value | Where-Object { $_.name -eq $DeploymentGroup }
$json = ConvertTo-Json $result
write-host $json
if($result.Length -eq 1)
{
    Write-Host "Deployment Group $DeploymentGroup exists"
}
else
{
    #Create the deployment group
    Write-Host "Deployment Group $DeploymentGroup doesn't exist... Creating"
     $json = "{ ""description"":""$Description"",""name"": ""$DeploymentGroup"" }"
    Write-Host $json
 $url = "https://dev.azure.com/EnsembleHealth/EIQ/_apis/distributedtask/deploymentGroups?api-version=6.0-preview.1"
 $response = Invoke-RestMethod $url -Headers $headers -Method POST -Verbose -Body $json -ContentType "application/json"
    Write-Host $response
}