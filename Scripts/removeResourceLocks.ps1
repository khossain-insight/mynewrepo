param (
	
	[string]
    [Parameter(Mandatory = $false)]
    $resourceGroupList,

	[string]
    [Parameter(Mandatory = $false)]
    $resourceTypeList, #Landing Zone

	[System.Object]
    [Parameter(Mandatory = $false)]
    $resourceKeyValue
    
)
# Resouce Group Lock apply to all resources in the resource group therefore need to ALWAYS remove them
# NOTE: Removing lock from resource group will remove all locks including resource locks!
# resourceType eg Microsoft.Storage/storageAccounts

$resourceGroupNames = $resourceGroupList.split(",")
#Resource Group Locks
if ($resourceTypeList)
{
	$resourceTypes = $resourceTypeList.split(",")
	#Resource Locks
	if ($resourceTypes)
	{
		foreach ($rg in $resourceGroupNames)
		{
			foreach ($resourceType in $resourceTypes)
			{
				$resourcesOfType = Get-AzResource -ResourceGroupName $rg -ResourceType $resourceType
				foreach ($resourceOfType in $resourcesOfType)
				{
					$lockIds = (Get-AzResourceLock -ResourceGroupName $rg -ResourceName $resourceOfType.name -ResourceType $resourceType).LockId
					if ($lockIds)
					{
						foreach ($lockId in $lockIds)
						{
							write-host ('[INFO] Removing Resource lock(s) on : {0}' -f $resourceOfType.name)
							Remove-AzResourceLock -LockId $lockId -force
						}
					}
				}
			}
		}	
	}
}
elseif ($resourceGroupList) #Resource Group Locks (all locks including resources)
{
	foreach ($rg in $resourceGroupNames)
	{
		$lockIds = (Get-AzResourceLock -ResourceGroupName $rg).LockId 
		foreach ($lockId in $lockIds)
		{
			write-host "[INFO] Removing Resource Group lock(s) on RG - $rg"
			Remove-AzResourceLock -LockId $lockId -force
		}
	}
}
elseif ($resourceKeyValue) # resource lock on specific resource
{
	#$resourceKeyValue = @{resourceGroup="";resourceName="";resourceType=""}
	if (($resourceKeyValue.resourceGroup) -and ($resourceKeyValue.resourceName) -and ($resourceKeyValue.resourceType))
	{
		$lockIds = (Get-AzResourceLock -ResourceGroupName $resourceKeyValue.resourceGroup -ResourceName $resourceKeyValue.resourceName -ResourceType $resourceKeyValue.resourceType).LockId
		if ($lockIds)
		{
			foreach ($lockId in $lockIds)
			{
				write-host "[INFO] Removing Resource lock(s) on - $resourceName"
				Remove-AzResourceLock -LockId $lockId -force
			}
		}
		else
		{
			write-host ('[WARNING] No Resource Locks found on : {0} : in Resource Group : {1}' -f $resourceKeyValue.resourceName, $resourceKeyValue.resourceGroup)
		}
	}
}
else 
{
	write-host "[WARNING] Arguments are all null - No Resource Locks removed"
}