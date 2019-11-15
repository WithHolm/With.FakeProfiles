using namespace System.Net
using namespace System.io
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param(
    [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]$Request, 
    [hashtable]$TriggerMetadata
)

# . (Join-Path ([System.IO.FileInfo]$PSScriptRoot).Directory.FullName "Log.ps1")
# Set-FunctionLogging
import-module "az.storage"
$ProgresstableName = "Progress"

# $cs = [Microsoft.Azure.Cosmos. .CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
$cs = [Microsoft.Azure.Cosmos.Table.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
# [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($cs
[Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($cs.TableEndpoint,$cs.Credentials)
[Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference($ProgresstableName)


# $Table
# Get-AzTableTable -
# $cs|convertto-json -depth 10
# Write-LogInformation "Connecting to storageaccount '$($CS.credentials.AccountName)'"
# $sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
# Write-LogInformation "Connecting to Table '$ProgresstableName'"
# $Progresstable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName $ProgresstableName
# gci env:
$ImportEntitys = Get-AzTableRow -Table $Table
$status = [HttpStatusCode]::Accepted
$body = [ordered]@{
    ImportImage = [ordered]@{
        Total = $(($ImportEntitys|?{$_.PartitionKey -eq 'ImportImage'}|ForEach-Object{$_.count}|Measure-Object -Sum).sum)
        NotCompleted = $(($ImportEntitys|?{$_.PartitionKey -eq 'ImportImage' -and $_.finished -eq $false}|ForEach-Object{$_.count}|Measure-Object -Sum).sum)
        Completed = $(($ImportEntitys|?{$_.PartitionKey -eq 'ImportImage' -and $_.finished -eq $true}|ForEach-Object{$_.count}|Measure-Object -Sum).sum)
    }
}

# $body = "hey"
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
