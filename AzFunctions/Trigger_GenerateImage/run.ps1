# Input bindings are passed in via param block.
param([string] $QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
ipmo (join-path (split-path $PSScriptRoot) "AzFnHelp") -Force
$JobTable = Get-FnTableFast -Name "jobs" -Connectionstring $env:AzureWebJobsStorage -CreateIfNotExist


# $QueueItem
# "*****"
# $TriggerMetadata

$PartitionKey = "GenerateImage"
$Row = (Get-AzTableRow -Table $JobTable -PartitionKey $PartitionKey -RowKey $QueueItem)
if($row.value -gt 1)
{
    $Children = @()
    Write-Information "Converting $($row.value) rows from $QueueItem"
    for ($i = 0; $i -lt $row.value; $i++) {
        $ID = [guid]::NewGuid().Guid
        $Property=@{
            Comment = $row.comment
            Children = ""
            Completed = $false
            Parent = $QueueItem
            Tag = "Waiting"
            Value = 1
        }
        [void](Add-AzTableRow -RowKey $ID -PartitionKey $PartitionKey -Table $JobTable -property $Property)
        $Children += $ID
    }
    $rowproperties = Convertfrom-FnTableEntity -TableEntity $Row -AsHashTable 
    $rowproperties.Children = $Children|ConvertTo-Json -AsArray
    $rowproperties.Comment = "Created subjobs"
    # $rowproperties
    [void](Add-AzTableRow -Table $JobTable -RowKey $QueueItem -PartitionKey $PartitionKey -property $rowproperties -UpdateExisting)
}

if(Set-FnSingletonFlag -Enable -Name "ProcessFace" -ConnectionString $env:AzureWebJobsStorage -Verbose)
{
    $rows = Get-AzTableRow -Table $JobTable -CustomFilter "PartitionKey eq 'GenerateImage' and Completed eq false and Value eq 1"
    $rows.count
    # $StopProcess = $false
    # While($StopProcess -eq $false)
    # {
    #     $StopProcess = $false
    # }
    Set-FnSingletonFlag -Disable -Name "ProcessFace" -ConnectionString $env:AzureWebJobsStorage
}