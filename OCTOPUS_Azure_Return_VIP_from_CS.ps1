function Get-AzureDeploymentIP{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CloudServiceName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Slot
    )

    try
    {
        return (Get-AzureDeployment -ServiceName $CloudServiceName -Slot $Slot).VirtualIPs.Address
    }
    catch
    {
        throw $_
    }

}

function Get-CloudServiceVIp {

    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CloudServiceName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Slot,
        [Parameter(Mandatory = $false)]
        [string]$OutputOctopusVariable
    )

    Add-RoleModules
    Initialize-AzureSubscription

    $CloudServiceVIp = Get-AzureDeploymentIP -CloudServiceName $CloudServiceName -Slot $Slot

    if ([String]::IsNullOrEmpty($CloudServiceVIp))
    {
        throw "CloudService named $CloudServiceName in slot $Slot not found."
    }

    if (Get-Command Set-OctopusVariable -ErrorAction SilentlyContinue)
    {
        Set-OctopusVariable -name $OutputOctopusVariable -value $CloudServiceVIp
    }

    Write-Verbose "CloudService VIp $CloudServiceVIp assigned to OctopusVariable: $OutputOctopusVariable"

}

if (Test-Path Variable:OctopusParameters)
{
    Get-CloudServiceVIp `
		-CloudServiceName $OctopusParameters['pCloudServiceName'] `
		-Slot $OctopusParameters['pSlot'] `
		-OutputOctopusVariable $OctopusParameters['pOutputOctopusVariable']
}