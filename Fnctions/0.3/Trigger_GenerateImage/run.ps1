# Input bindings are passed in via param block.
param([string] $QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
ipmo (join-path (split-path $PSScriptRoot) "AzFnHelp") -Force
$JobTable = Get-FnTableFast -Name "jobs" -Connectionstring $env:AzureWebJobsStorage -CreateIfNotExist
$MaxValueInTable = 1
$StorageBlob = "pictures"

# $QueueItem
# "*****"
# $TriggerMetadata

$PartitionKey = "GenerateImage"
$Row = (Get-AzTableRow -Table $JobTable -PartitionKey $PartitionKey -RowKey $QueueItem)
if(([int]$row.value) -gt $MaxValueInTable)
{
    $Children = @()
    Write-Information "Converting $($row.value) rows from $QueueItem"
    for ($i = 0; $i -lt $row.value; $i+=$MaxValueInTable) {
        $ID = [guid]::NewGuid().Guid
        $Property=@{
            Comment = $row.comment
            Children = ""
            Completed = $false
            Parent = $QueueItem
            Tag = "Waiting"
            Value = $MaxValueInTable
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
    $rows = Get-AzTableRow -Table $JobTable -CustomFilter "PartitionKey eq 'GenerateImage' and Completed eq false and Value lt $($MaxValueInTable + 1)"
    $BatchSize = 10
    $count = @($rows).Count
    $parts = [math]::Ceiling($count / $BatchSize)
    . "$PSScriptRoot\getprofilepictures.ps1"
    #
    $cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
    $SA = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
    $container = $sa|Get-AzStorageContainer -name $StorageBlob

    Write-Information "Split $count imports to $parts parts (max batch size:$BatchSize)"
    for($i=1; $i -le $parts; $i++){
        $Chunk = $i*$BatchSize
        if($Chunk -gt $Count)
        {
            $Chunk = $BatchSize-($Chunk-$count)
        }
        else 
        {
            $Chunk = $BatchSize
        }

        $Min = (($i-1)*$BatchSize)
        $Max = ($Min+$Chunk)
        Write-debug "$i/$parts -> $Chunk"
        Write-Information "Processing index $Min -> $max"
        $ProcessRows = @($rows)[$min..$max]
        $ProcessRows|%{
            $properties = (Convertfrom-FnTableEntity -TableEntity $_ -AsHashTable)
            $properties.comment = "Downloading"
            $properties.tag = "Processing"
            [void](Add-AzTableRow -PartitionKey $_.PartitionKey -RowKey $_.rowkey -property $properties -UpdateExisting -Table $JobTable)
        }

        $_Count = 0
        $workers = @()
        $LocalStorage = "$env:TEMP\Pic\$([guid]::NewGuid().Guid)"
        [void](new-item -ItemType Directory -Path $LocalStorage -Force)

        Get-RandomFace -OutputFolder $LocalStorage -Amount ($ProcessRows.value|Measure-Object -Sum).Sum -Verbose -passthru|%{
            $currentrow = (Get-AzTableRow -Table $JobTable -RowKey $ProcessRows[$_count].rowkey -PartitionKey $ProcessRows[$_count].PartitionKey) 
            $BlobName = "$($currentrow.rowkey)\Import.jpeg"
            Write-Information "Uploading $($currentrow.rowkey) to blob '$($SA.StorageAccountName)':'$BlobName'"
    
            #Get Blobreference
            $ref = $container.CloudBlobContainer.GetBlockBlobReference($BlobName)
    
            #Set Blob ContentType
            $ref.Properties.ContentType = "application/octet-stream"
    
            #Upload to Blobstorage
            $workers += $ref.UploadFromFileAsync($_.fullname)

            $properties = (Convertfrom-FnTableEntity -TableEntity $currentrow -AsHashTable)
            $properties.comment = "Downloaded image"
            $properties.completed = $true

            # $AddAzTableRowParam = @{
            #     PartitionKey = $currentrow.PartitionKey
            #     property = $properties
            #     UpdateExisting = $true
            #     RowKey = $currentrow.rowkey
            #     Table = $JobTable
            # }
            [void](Add-AzTableRow -PartitionKey $currentrow.PartitionKey -RowKey $currentrow.rowkey -property $properties -UpdateExisting -Table $JobTable)
            $_count++
        }
    }

    Set-FnSingletonFlag -Disable -Name "ProcessFace" -ConnectionString $env:AzureWebJobsStorage
}