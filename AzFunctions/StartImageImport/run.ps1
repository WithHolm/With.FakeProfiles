using namespace System.Net
using namespace System.io
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param(
    [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]$Request, 
    [hashtable]$TriggerMetadata
)

. (Join-Path ([System.IO.FileInfo]$PSScriptRoot).Directory.FullName "Log.ps1")
Set-FunctionLogging
import-module "az.storage"
$ProgresstableName = "Progress"

$Count = $Request.Query.count
if([string]::IsNullOrEmpty($Request.Query.count) -or $Count -eq 0)
{
    $count = 1
    write-LogInformation "Count not detected.. setting to $count"
}

Write-LogInformation "Count: $count"

$cs = [Microsoft.Azure.Cosmos.Table.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
Write-LogInformation "Creating tableclient for account '$($CS.TableEndpoint)'"
[Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($cs.TableEndpoint,$cs.Credentials)
[Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference($ProgresstableName)

$status = [HttpStatusCode]::Accepted
# $timespan = [timespan]::FromSeconds($count*4)
$body = [ordered]@{
    result = $true
    TimeStamp = [datetime]::Now
    message = "Added $count pictures to importlist"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

$BatchSize = 5
$parts = [math]::Ceiling($count / $BatchSize)
Write-LogInformation "Split $count imports to $parts parts (max batch size:$BatchSize)"
for($i=1; $i -le $parts; $i++){
    $Chunk = $i*$BatchSize
    if($Chunk -gt $Count)
    {
        $Chunk = $BatchSize-($Chunk-$count)
    }
    else {
        $Chunk = $BatchSize
    }

    Write-LogInformation "$i/$parts"
    #TPDNE = ThisPersonDoesNotExist
    [void](Add-AzTableRow -Table $Table -PartitionKey "ImportImage" -RowKey $([guid]::NewGuid().Guid) -property @{Count=$Chunk;Finished=$false;Source="TPDNE"})
}