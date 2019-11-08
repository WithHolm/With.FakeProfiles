using namespace System.Net
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param(
    [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]$Request, 
    [hashtable]$TriggerMetadata
)
import-module "az.storage"
# $StorageBlob = "pictures"
$ImportQName = "imgimportqueue"
$StartQName = "imgimportstart"
$BatchSize = 30

$Count = $Request.Query.count
if([string]::IsNullOrEmpty($Request.Query.count) -or $Count -eq 0)
{
    $count = 1
    Write-Information "Count not detected.. setting to $count"
}

Write-Information "Count: $count"

$cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
$sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}

Write-Information "Gettting storage queues '$ImportQName' and '$StartQName'"
$ImportQ = @($sa|Get-AzStorageQueue).Where{$_.name -eq $ImportQName}
$startQ = @($sa|Get-AzStorageQueue).Where{$_.name -eq $StartQName}

#how many parts do i need to split the total in to get the correct batch size.
$parts = [math]::Ceiling($count / $BatchSize)
Write-Information "Split $count imports to $parts parts (max batch size:$BatchSize)"
for($i=1; $i -le $parts; $i++){
    $Chunk = $i*$BatchSize
    if($Chunk -gt $Count)
    {
        $Chunk = $BatchSize-($Chunk-$count)
    }
    else {
        $Chunk = $BatchSize
    }
    $message = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($Chunk,$false)
    [void]$ImportQ.CloudQueue.AddMessageAsync($message)
    Write-Information "This batch size: $Chunk"
}

#Add reference to table to check when starting the stagnated job
$message = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($ImportQName,$false)
[void]$startQ.CloudQueue.AddMessageAsync($message)

$status = [HttpStatusCode]::Accepted
$timespan = [timespan]::FromSeconds($count*4)
$body = [ordered]@{
    result = $true
    TimeStamp = [datetime]::Now
    message = "Started import of $count pictures"
}
# gci env:

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
