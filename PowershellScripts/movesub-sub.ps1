#Requires -PSEdition Desktop
## https://dev.azure.com/cloud1public/_git/Blog%20Source?path=%2FValidate_Move_AzureResources.ps1

function Get-AzureValidateResourceMoveResult
{
    <#
    .SYNOPSIS
        Function to call Azure Validation API
    .EXAMPLE
        PS C:\>$validateSplat = @{
        >> SourceSubscriptionID = '11111111-1111-1111-1111-111111111111'
        >> SourceResourceGroupName = 'Sample Resourcegroup1'
        >> TargetResourceGroupName = 'Sample Resourcegroup2'
        >> }

        PS C:\> Validate-ResourceMove @validateSplat
    #>
    [CmdletBinding()]
    param (
        # Source Azure Subscription ID
        [Parameter(Mandatory)]
        [guid]$SourceSubscriptionID,

        # Target Azure Subscription ID (if omited the script assumes that the move would happen within the source Azure Subscription)
        [guid]$TargetSubscriptionID = $SourceSubscriptionID,

        # Source resourcegroup name
        [Parameter(Mandatory)]
        [string]$SourceResourceGroupName,

        # Target resourcegroup name
        [Parameter(Mandatory)]
        [string]$TargetResourceGroupName,

        # List of resource types to be excluded from the validation
        [object[]]$excludedResourceTypes
    )

    # Check if the login is required
    $currentContext = (Get-AzContext).Subscription.SubscriptionId
    if(!$currentContext) {
        Login-AzAccount -SubscriptionId $sourceSubscriptionID
    }
    if($currentContext -ne $SourceSubscriptionID) {
        Select-AzSubscription -SubscriptionId $SourceSubscriptionID
    }

    # Get a Bearer token
    $currentAzureContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    $token = "Bearer " + $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId).AccessToken

    # Create an array of resources to be validated
    $resourceIDs = foreach ($resource in (Get-AzResource -ResourceGroupName $SourceResourceGroupName)) {
        $included = $true
        if ($null -ne $resource.ParentResource) {
            # Skip resources with parents. Validation will fail if the list contains child resources.
        }
        else {
            foreach ($excludedResourceType in $excludedResourceTypes) {
                if ($resource.ResourceType -eq $excludedResourceType) {
                    # Do not add a resource if its type is in the excluded resource types list.
                    write-host "Excluding resource: $($resource.resourceId)" -ForegroundColor Yellow
                    $included = $false
                }
            }
            if ($included) {
                $resource.resourceId
            }
        }
    }
    if (!$resourceIDs) {
        Write-Warning "No resources to be validated!"
        return
    }
    elseif ($resourceIDs.GetType().Name -eq 'String') {
        # This is needed if there is only one resource to be validated. Code below expects an array.
        $resourceIDs = @($resourceIDs)
    }

    # Prepare the body of the request and other parameters for Invoke-WebRequest
    $body = @{
        resources=$resourceIDs ;
        TargetResourceGroup = "/subscriptions/$targetSubscriptionID/resourceGroups/$targetresourceGroupName"
    } | ConvertTo-Json

    $requestSplat = @{
        Uri = "https://management.azure.com/subscriptions/$sourceSubscriptionID/resourceGroups/$sourceresourceGroupName/validateMoveResources?api-version=2020-07-01"
        Method = 'Post'
        Body = $body
        ContentType = 'application/json'
        Headers = @{Authorization = $token}
    }

    try {
        # Send the validation request
        $return = Invoke-WebRequest  @requestSplat -ErrorAction Stop
    }
    catch {
        # This part will catch an error if the request fails immediately. Like on the case child resources
        $FormattedError1 = $_|ConvertFrom-Json
        Write-host "Error code: "  $FormattedError1.error.code -ForegroundColor Red
        Write-host "Error Message: " $FormattedError1.error.message -ForegroundColor Red
        Write-host "Error details: " -ForegroundColor Red
        $FormattedError1.error.details|Format-List *
        throw "Error occured. Cannot continue."
    }

    # Prepare the parameters for the second Invoke-WebRequest
    $resultSplat = @{
        Uri = $($return.Headers.Location)
        Method = 'Get'
        ContentType = 'application/json'
        Headers = @{Authorization = $token}
    }

    # Wait for the validation result
    do {
        Write-Host 'Waiting for validation result to be ready ...'
        Start-Sleep -Seconds $return.Headers.'Retry-After'

        try {
            $status = Invoke-WebRequest @resultSplat -ErrorAction Stop
        }
        catch {
            # This will catch any errors. Most likely error is from failed validation and contains the details why the validation failed.
            $FormattedError2 = $_.ErrorDetails.Message|ConvertFrom-Json
            Write-host "Error code: "  $FormattedError2.error.code -ForegroundColor Red
            Write-host "Error Message: " $FormattedError2.error.message -ForegroundColor Red
            Write-host "Error details: " -ForegroundColor Red
            $FormattedError2.error.details|Format-List *
            break
        }
    } while($status.statusCode -eq 202)

    if($status.statusCode -eq 204){
        Write-Host "Validation succeeded" -ForegroundColor Green
    }
}

#region Main
# List of excluded resource types. The ones that are known to fail.
$excludedResourceTypes = @('Microsoft.Synapse/workspaces')

$validateSplat = @{
    SourceSubscriptionID = '<Insert Subscription ID here>'
    SourceResourceGroupName = '<Insert resourcegroup name here>'
    TargetSubscriptionID = '<Insert Subscription ID here>'
    TargetResourceGroupName = '<Insert resourcegroup name here>'
    ExcludedResourceTypes = $excludedResourceTypes
}

Get-AzureValidateResourceMoveResult @validateSplat
#endregion Main