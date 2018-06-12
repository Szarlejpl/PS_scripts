function Add-SqlAzureServer{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerVersion,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$SqlAdministratorCredentials,
		[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PlatformTag,
		[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StageTag
    )
    try
    {
        New-AzureRmSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Location $Location -ServerVersion $ServerVersion -SqlAdministratorCredentials $credential -Tag @{Platform=$PlatformTag; Stage=$StageTag}
    }
    catch
    {
        ("Could not create new SqlAzure database server `"$ServerName`" with version `"$ServerVersion`" in resource group `"$ResourceGroupName`" in location `"$Location`". `n{0}" -f $Error[0].Exception.Message)
        throw $_
    }
    

}

function Add-AzureActiveDirectoryAdmin{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ActiveDirectoryAdmin
    )
    try
    {
        Set-AzureRmSqlServerActiveDirectoryAdministrator  -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DisplayName $ActiveDirectoryAdmin
    }
    catch
    {
        ("Could not set Azure Active Directory Admin {0} on database server {1}" -f $ActiveDirectoryAdmin,$ServerName)
        throw $_
    }
    

}

function Test-ResourceGroupExist{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName
    )

    try
    {
        [bool]$exists = $false
        Get-AzureRmResourceGroup -Name $ResourceGroupName    
        $exists = $true
    }
    catch
    {
        if ($Error[0].Exception.Message -eq 'Provided resource group does not exist.')
        {
            return $exists
        }
        else
        {
            throw $_
        }
    }

    return $exists

}

function Test-SqlAzureServerName {
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName
    )

    

    if ($ServerName -cnotmatch '^([a-z0-9]+)([-]*[a-z0-9]*)*[^-]$')
    {
        throw "Servername failed naming rules: `"$Servername`" cannot be empty or null. It can only be made up of lowercase letters 'a'-'z', the numbers 0-9 and the hyphen. The hyphen may not lead or trail in the name."
    }

    if ($ServerName.Length -gt 63)
    {
        throw "$ServerName exceeds max name length of 63 chars."
    }

}


function Test-AzureSqlServerActiveDirAdmin {
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ActiveDirectoryAdmin,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName
    )

    try
    {
        $existingAzureRmActiveDirAdmin = Get-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $ServerName

        if ($null -ne $existingAzureRmActiveDirAdmin) {

            if($existingAzureRmActiveDirAdmin.DisplayName -eq $ActiveDirectoryAdmin)
            {
                $ADAdminexists = $true
            }
        }
        else {
            $ADAdminexists = $false
        }
    }
    catch
    {
         throw "Could not determine if Azure Active Directory Admin already exists on Sql Server {0}" -f $ServerName
    }

    return $ADAdminexists
}

function New-SqlAzureServer {

    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerVersion,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlAdminUsername,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlAdminPassword,
        [Parameter(Mandatory = $false)]
        [string]$ActiveDirectoryAdmin,
		[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PlatformTag,
		[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StageTag
    )

    Add-RoleModules
    Setup-AzureRmSubscription

    try
    {
        $CheckResourceGroupExists = Test-ResourceGroupExist -ResourceGroupName $ResourceGroupName

    }
    catch
    { 
        throw $_
    }

    if ($CheckResourceGroupExists -eq $false)
    {
        throw ("Resource group `"$ResourceGroupName`" not found.")
    }

    try
    {
        Test-SqlAzureServerName -ServerName $ServerName
    }
    catch
    {
        throw
    }

    try
    {
        $existingAzureRmSqlServer = Get-AzureRmSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ErrorAction Stop
    	Write-Host "Checking server $ServerName"
        Write-Host $existingAzureRmSqlServer
    }
    catch
    {
        if ($Error[0].Exception.Message -like "*`'$ResourceGroupName`' was not found*" -or $Error[0].Exception.Message -like "*'Microsoft.Sql/servers' with name `'$ServerName`' was not found*") 
        { 
            Write-Host ('SqlAzure Server {0} not found.' -f $ServerName)
        }
        else
        {
            throw ("Could not determine if SqlAzure Database already exists`n{0}" -f $Error[0])
        }
    }
 

    try
    {
        if ($null -eq $existingAzureRmSqlServer)
        {
            $securepassword = $SqlAdminPassword | ConvertTo-SecureString -AsPlainText -Force
            $credential = New-Object PSCredential -ArgumentList $SqlAdminUsername,$securepassword
            Add-SqlAzureServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Location $Location -ServerVersion $ServerVersion -SqlAdministratorCredentials $credential -PlatformTag $PlatformTag -StageTag $StageTag
        }
        else
        {
            Write-Verbose ($existingAzureRmSqlServer | Format-List | Out-String)
            Write-Host 'The SqlServer already exists, Use Set-AzureRmSqlServer cmdlet to update the settings.'
        }
    }
    catch
    {
        throw
    }

    if($ActiveDirectoryAdmin)
    {
        try
        {
            $ADAdminexists = Test-AzureSqlServerActiveDirAdmin -ServerName $ServerName -ResourceGroupName $ResourceGroupName -ActiveDirectoryAdmin $ActiveDirectoryAdmin

            if(!$ADAdminexists) {
                Write-Output ("Azure Active Directory Admin {0} does not exist on Sql Server {1}. Creating..."  -f $ActiveDirectoryAdmin,$ServerName)
                Add-AzureActiveDirectoryAdmin -ServerName $ServerName -ResourceGroupName $ResourceGroupName -ActiveDirectoryAdmin $ActiveDirectoryAdmin
            }
            else
            {
                Write-Output ("Azure Active Directory Admin {0} already exists on Sql Server {1}"  -f $ActiveDirectoryAdmin,$ServerName)
            }
        }
        catch
        {
            throw
        }
    }
}

if (Test-Path Variable:OctopusParameters)
{
    New-SqlAzureServer -ServerName $ServerName -ResourceGroupName $ResourceGroupName -Location $Location -ServerVersion $ServerVersion -SqlAdminUsername $SqlAdminUsername -SqlAdminPassword $SqlAdminPassword -ActiveDirectoryAdmin $ActiveDirectoryAdmin -PlatformTag $PlatformTag -StageTag $StageTag
}