
#https://johanbostrom.se/blog/moving-all-azure-resources-from-one-resource-group-to-another-across-subscriptions/

$sourceSubId = "11111111-1111-1111-1111-111111111111" # Subscription you want to move resources from
$destSubId = "22222222-2222-2222-2222-222222222222" #     Subscription you want to move resources to

$sourceResourceGroup = "ResourceGroupOld" # Name of the resource group your moving resources from
$destResourceGroup = "ResourceGroupNew" # Name of the resource group your moving resources to

$nonMovableTypes = @('microsoft.insights/components','Microsoft.ClassicStorage/storageAccounts','Microsoft.Compute/virtualMachines/extensions','Microsoft.Sql/servers/databases') # These are the types that cannot be moved
$typeToMoveSeparate = @() # These are the types that must be moved separately

try
{
    Select-AzureRmSubscription -SubscriptionId $sourceSubId

    $groupResources = Find-AzureRmResource -ResourceGroupNameContains $sourceResourceGroup
    $resourceIds = @()
    $moveSeparateResources = @()

    foreach ($r in $groupResources)
    {
        if ($nonMovableTypes.Contains($r.ResourceType)) {
            continue
        }

        if ($typeToMoveSeparate.Contains($r.ResourceType)) {
            $moveSeparateResources = $moveSeparateResources + $r;
        } else {
            $resourceIds = $resourceIds + $r.ResourceId;
        }
    }

    if ($resourceIds.Count.Equals(0) -and $moveSeparateResources.Count.Equals(0))
    {
        "No resources to move"
    }
    else
    {
        if (!$resourceIds.Count.Equals(0)) {
            "Started moving " + $resourceIds.Count + " resources";
            Move-AzureRmResource -DestinationResourceGroupName $destResourceGroup -ResourceId $resourceIds -DestinationSubscriptionId $destSubId -Verbose
        }

        foreach ($r in $moveSeparateResources) {
            "Moving type " + $r.ResourceType + ""
            Move-AzureRmResource -DestinationResourceGroupName $destResourceGroup -ResourceId $r.ResourceId -DestinationSubscriptionId $destSubId -Verbose
        }
 
        "Move done!"
    }
}
catch
{
    Write-Error($_)
}