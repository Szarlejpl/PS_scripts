function Set-StorageAccount {

    param (
        [Parameter(Mandatory=$true)]
        [ValidateLength(3,24)]
        [string]$StorageAccountName,
        [string]$ResourceGroupName,
        [ValidateSet("Premium_LRS","Standard_GRS","Standard_LRS","Standard_RAGRS","Standard_ZRS")]
        [string]$Type,
        [string]$Location,
		[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PlatformTag,
		[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StageTag
    )

    Add-RoleModules

    Setup-AzureRmSubscription

    # First check the resource group exists, if not create
    if ($null -eq (Get-AzureRmResourceGroup | Where-Object { $_.ResourceGroupName -eq $ResourceGroupName }))
    {
        throw ("Resource group {0} does not exist in this subscription. Use a step to create the resource group before this step is run." -f $ResourceGroupName)
    }

    # Create the storage account if it doesn't exist
    $StorageAccountNameLower = $StorageAccountName.ToLower();

    $checkStorageAccount = Find-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" -ResourceNameContains $StorageAccountNameLower -ApiVersion "2016-07-01"

    if ($null -eq $checkStorageAccount)
    {
        Write-Verbose ("Storage Account {0} does not exist, creating" -f $StorageAccountNameLower)

        New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountNameLower -Type $Type -Location $Location -Tag @{Platform=$PlatformTag; Stage=$StageTag}
    }
    else
    {
        Write-Verbose ("Storage account {0} already exists" -f $StorageAccountNameLower)

		# Ensuring there are no more than 1 storage account as Find-AzureRmResource uses the parameter ResourceNamContains which is greedy
		if ($checkStorageAccount.ResourceGroupName.count -ne 1)
		{
			$checkStorageAccount = $checkStorageAccount | Where-Object{$_.name -eq $StorageAccountNameLower}
		}

        $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $checkStorageAccount.ResourceGroupName -Name $checkStorageAccount.ResourceName

        if ($storageAccount.AccountType -ne ($Type -replace "_"))
        {
            Write-Verbose ("Account type of Storage Account {0} ({1}) does not match desired ({2}), modifying" -f $StorageAccountNameLower, $storageAccount.AccountType, $Type)
            Set-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountNameLower -Type $Type
        }
    }
}

if (Test-Path Variable:OctopusParameters)
{
    Set-StorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Type $Type -Location $Location -PlatformTag $PlatformTag -StageTag $StageTag
}