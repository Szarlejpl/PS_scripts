Add-AzureAccount
Select-AzureSubscription -SubscriptionName AsosCommercePreprod

$serviceNames = (Get-AzureService | Select ServiceName).servicename

#$serviceNamesCutDown = select $serviceNames

$cloud_services = @()

foreach($serviceName in $serviceNames)
{
   $instanceCount = Get-AzureRole -ServiceName $serviceName | Measure InstanceCount -Sum | select sum -ExpandProperty sum
   $rolecount = (get-azurerole $serviceName | Measure-Object -Property RoleName).count
   $rolenames = (get-azurerole $serviceName).RoleName
   $cloud_services+=New-Object psobject -Property $([ordered]@{
   Service_Name = $serviceName
   Instance_Count = $instanceCount
   Role_count = $rolecount
   Role_Names = $rolenames -join ','
   })
}
$cloud_services | export-csv azure.csv -notype
