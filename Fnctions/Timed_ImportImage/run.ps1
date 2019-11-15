using namespace System.Net
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param($Timer)
import-module "az.storage"

##Singleton issue:
#https://github.com/Azure/azure-functions-host/issues/912
# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

#INIT
$EndSecondsBuffer = 20
$MaxTime = ($Timer.ScheduleStatus.Next - $Timer.ScheduleStatus.Last)
$Finishby = [datetime]::Now.ToUniversalTime().AddSeconds($maxtime.TotalSeconds)
. "$PSScriptRoot\getprofilepictures.ps1"
$maxbatchprocess = 10
$QueueName = "imgimportq"
$ProgresstableName = "Progress"
$StorageBlob = "pictures"
$LocalStorage = "$env:TEMP\Pic\$([guid]::NewGuid().Guid)"

$cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
$SA = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
$container = $sa|Get-AzStorageContainer -name $StorageBlob
# $Queue = $sa|Get-AzStorageQueue|?{$_.name -eq $QueueName}
$Progresstable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName $ProgresstableName


# Write an information log with the current time.
Write-Host "PowerShell THIS timer trigger function ran! TIME: $currentUTCtime. will process untill $($Finishby.ToString()) - $EndSecondsBuffer seconds"

# Add-AzTableRow -Table $Progresstable -PartitionKey "ImportImage" -RowKey $([guid]::NewGuid().Guid) -property @{Count=1;Finished=$false;Source="TPDNE"}
$ImportEntitys = Get-AzTableRow -Table $Progresstable -CustomFilter "PartitionKey eq 'ImportImage' and Finished eq false and Count lt $maxbatchprocess"

Write-Information "Found $(@($ImportEntitys).count) entities. processing as many as i can before timer runs out.."
new-item -ItemType Directory -Path $LocalStorage -Force
$workers = @()
:Import for ($i = 0; $i -lt @($ImportEntitys).Count; $i++)
{
    # $thisArrayCount = $i
    Get-RandomFace -OutputFolder $LocalStorage -Amount $ImportEntitys[$i].count -Verbose -passthru|%{
        $AzName = "Import\$($_.name)"
        Write-Information "Uploading $($_.name) to blob '$($SA.StorageAccountName)':'$AzName'"
        $ref = $container.CloudBlobContainer.GetBlockBlobReference($AzName)
        $ref.Properties.ContentType = "application/octet-stream"
        $workers += $ref.UploadFromFileAsync($_.fullname)
    }
    # # $ImportEntitys.Finished = $true
    $UpdateProperties = @{}
    $ImportEntitys[$i].psobject.properties|?{$_.name -notin @("etag","tabletimestamp","Rowkey","partitionkey")}|%{
        $UpdateProperties.$($_.name) = $_.value
    }
    $UpdateProperties.finished = $true
    Write-Information "Would update $($ImportEntitys[$i].partitionkey)/$($ImportEntitys[$i].Rowkey): $($updateproperties|convertto-json -compress)"
    [void](Add-AzTableRow -Table $Progresstable -PartitionKey $ImportEntitys[$i].partitionkey -RowKey $ImportEntitys[$i].Rowkey -property $UpdateProperties -UpdateExisting)

    if([datetime]::UtcNow.AddSeconds($EndSecondsBuffer) -gt $Finishby)
    {
        Write-Information "Ending this run with $(($Finishby - [datetime]::UtcNow).TotalSeconds) seconds to spare"
        break :Import
    }
}

while($false -in $workers.IsCompleted)
{
    Write-Information "Waiting for blobupload ($(@($workers|?{$_.iscompleted}).count)/$($workers.Count))"
    Start-Sleep -Milliseconds 500
}

remove-item $LocalStorage -Force -Recurse

# Get-RandomFace -OutputFolder $LocalStorage -Amount $ImportCount -Verbose -passthru|%{
#     $AzName = "Import\$($_.name)"
#     Write-Information "Uploading $($_.name) to blob '$($SA.StorageAccountName)':'$AzName'"
#     $ref = $container.CloudBlobContainer.GetBlockBlobReference($AzName)
#     $ref.Properties.ContentType = "application/octet-stream"
#     $workers += $ref.UploadFromFileAsync($_.fullname)
# }
# while($false -in $workers.IsCompleted)
# {
#     Write-Information "Waiting for blobupload ($(@($workers|?{$_.iscompleted}).count)/$($workers.Count))"
#     Start-Sleep -Milliseconds 500
# }

# $Timer = [System.Diagnostics.Stopwatch]::StartNew()
# import-module "az.storage"
# $StorageBlob = "pictures"

# #Loading 


# $cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
# Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
# $sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
# $Progresstable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName $ProgresstableName
# $LockQueue = $sa|Get-AzStorageQueue|?{$_.name -eq $QueueItem}


# #Connect to Container to set pictures and to Import queue 
# $cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
# Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
# $sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
# $LockContainter = $sa|Get-AzStorageContainer -name $LockContainterName
# $LockFile = $LockContainter.CloudBlobContainer.GetBlockBlobReference('ImportImage')
# if(!$LockFile.Exists())
# {
    
# }
# else {
#     return "Another instance running.. wont do anything"
# }

# $container = $sa|Get-AzStorageContainer -name $StorageBlob
# $Importqueue = $sa|Get-AzStorageQueue|?{$_.name -eq $QueueItem}
# if(!$Importqueue)
# {
#     Throw "Cannot find the importqueue '$QueueItem'"
# }

# #Import first message from messagequeue, and remove it from the queue
# $invisibleTimeout = [System.TimeSpan]::FromMinutes(10)
# $queueMessage = $Importqueue.CloudQueue.GetMessage($invisibleTimeout,$null,$null)
# $ImportCount = [int]::Parse($queueMessage.AsString)
# [void]$Importqueue.CloudQueue.DeleteMessageAsync($queueMessage)

# # Write-Information $Importqueue.CloudQueue.ApproximateMessageCount

# $LocalStorage = "$env:TEMP\Pic\$([guid]::NewGuid().Guid)" 
# Write-Information "Getting faces"
# $workers = @()
# Get-RandomFace -OutputFolder $LocalStorage -Amount $ImportCount -Verbose -passthru|%{
#     $AzName = "Import\$($_.name)"
#     Write-Information "Uploading $($_.name) to blob '$($SA.StorageAccountName)':'$AzName'"
#     $ref = $container.CloudBlobContainer.GetBlockBlobReference($AzName)
#     $ref.Properties.ContentType = "application/octet-stream"
#     $workers += $ref.UploadFromFileAsync($_.fullname)
# }
# while($false -in $workers.IsCompleted)
# {
#     Write-Information "Waiting for blobupload ($(@($workers|?{$_.iscompleted}).count)/$($workers.Count))"
#     Start-Sleep -Milliseconds 500
# }
# gci $LocalStorage|remove-item -Force -Recurse