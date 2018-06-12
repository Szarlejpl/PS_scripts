function Get-AzureStorageAccountKey {

    param (
        [Parameter(Mandatory=$true)]
        [ValidateLength(3,24)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Primary','Secondary')]
        [string]
        $KeySelection,
        [Parameter(Mandatory=$true)]
        [string]
        $OutputOctopusVariable
    )

    Write-Verbose "StorageAccountName: $StorageAccountName"
    Write-Verbose "KeySelection: $KeySelection"

    Add-RoleModules
    Setup-AzureRmSubscription

    $StorageAccountNameLowercase = $StorageAccountName.ToLower();
    $storageAccount = Find-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" -ResourceNameContains $StorageAccountNameLowercase -ApiVersion "2016-07-01"
    if ($null -eq $storageAccount)
    {
        $errorMessage = "Storage Account [$StorageAccountNameLowercase] does not exist."
        throw $errorMessage
    }

	# Ensuring there are no more than 1 storage account as Find-AzureRmResource usees the parameter ResourceNamContains which is greedy
	if ($storageAccount.ResourceGroupName.count -ne 1)
	{
		$storageAccount = $storageAccount | Where-Object{$_.name -eq $StorageAccountNameLowercase}
	}

    $keys = Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -AccountName $StorageAccountName
    $PrimaryKey   = $keys[0].Value
    $SecondaryKey = $keys[1].Value

    if ($null -eq $PrimaryKey)
    {
        $PrimaryKey = $keys.Key1
    }

    if ($null -eq $SecondaryKey)
    {
        $SecondaryKey = $keys.Key2
    }

    if (Get-Command Set-OctopusVariable -ErrorAction SilentlyContinue)
    {
        Write-Verbose "Setting Dynamic Octopus Variable..."
        if ($KeySelection -eq "Primary") {
            Write-Verbose "Setting Octopus Variable to PrimaryKey"
            Set-OctopusVariable -name $OutputOctopusVariable -value $PrimaryKey
            return
        }

        Write-Verbose "Setting Octopus Variable to SecondaryKey"
        Set-OctopusVariable -name $OutputOctopusVariable -value $SecondaryKey
        return
    }

    Write-Verbose "Set-OctopusVariable command not found."
}

if (Test-Path Variable:OctopusParameters)
{
    Get-AzureStorageAccountKey -StorageAccountName $StorageAccountName -KeySelection $KeySelection -OutputOctopusVariable $OutputOctopusVariable
}