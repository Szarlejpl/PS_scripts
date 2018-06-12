$SQLlist = Get-AzureRmSqlServer
[Array]$AzureSQLList = $Null
Foreach ($server in $SQLlist)
{
$SQLName = $server.ServerName
$SQLResourceGroup = $server.ResourceGroupName
$AzureSQLList += @{

$SQLName = $SQLResourceGroup

}
}
$DBSizelist = $Null
Foreach ($SQLServer in $AzureSQLList.GetEnumerator())
{
$DatabaseList = Get-AzureRmSqlDatabase -ServerName $SQLServer.keys -ResourceGroupName $SQLServer.values -ErrorAction SilentlyContinue

Foreach ($DB in $DatabaseList){

$DBSizelist += @{

    $DB.DatabaseName = $DB.CurrentServiceObjectiveName
    
                }
                                }

}

$DBSizelist.GetEnumerator() | ? {$_.name -like "*cmc-orders*"} |Select-Object @{expression={$_.name};label="Database Name"},@{expression={$_.value};label="Database Size"} | Sort-Object Name |Export-Csv C:\temp\dbbysize.csv -Force -NoTypeInformation