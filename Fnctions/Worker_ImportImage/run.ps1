using namespace Microsoft.Azure.Storage

# Input bindings are passed in via param block.
param([string] $QueueItem, $TriggerMetadata)

import-module "az.storage"
$StorageBlob = "pictures"
$LockContainterName = "locks"
$CallingQueue = (((get-content "$PSScriptRoot\function.json" -Raw)|ConvertFrom-Json).bindings|?{$_.type -eq 'queueTrigger' -and $_.direction -eq "in"}).queueName

. "$PSScriptRoot\getprofilepictures.ps1"

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
<#
$TriggerMetadata
[09-Nov-19 02:06:33] OUTPUT: Name                           Value
[09-Nov-19 02:06:33] OUTPUT: ----                           -----
[09-Nov-19 02:06:33] OUTPUT: QueueTrigger                   test
[09-Nov-19 02:06:33] OUTPUT: PopReceipt                     AgAAAAMAAAAAAAAAU6plsqOW1QE=
[09-Nov-19 02:06:33] OUTPUT: FunctionDirectory              C:\Users\Phil\source\repos\With.FakeProfiles\AzFunctions\Worker_ImportImage
[09-Nov-19 02:06:33] OUTPUT: sys                            {RandGuid, UtcNow, MethodName}
[09-Nov-19 02:06:33] OUTPUT: DequeueCount                   1
[09-Nov-19 02:06:33] OUTPUT: NextVisibleTime                09-Nov-19 03:16:29
[09-Nov-19 02:06:33] OUTPUT: InvocationId                   283c662f-82a1-40aa-8994-008b2e1ed054
[09-Nov-19 02:06:33] OUTPUT: Id                             b275e5f5-4bcf-42ac-8fd1-43c429b5b376
[09-Nov-19 02:06:33] OUTPUT: ExpirationTime                 16-Nov-19 02:38:05
[09-Nov-19 02:06:33] OUTPUT: InsertionTime                  09-Nov-19 02:38:05
[09-Nov-19 02:06:33] OUTPUT: FunctionName                   Worker_ImportImage
#>


<#
    Triggered by message in imgimportstart with reference of where to get batch sizes = $

    Get first message from referenced queue, remove the message from queue. This should be an int
    Import this amount of pictures, give them a new GUID.
    Upload to blob/PictureGUID/Pictureguid.jpeg

    if there are more items to process, 
#>

#Connect to Container to set pictures and to Import queue 
$cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
$sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
$LockContainter = $sa|Get-AzStorageContainer -name $LockContainterName
$LockFile = $LockContainter.CloudBlobContainer.GetBlockBlobReference('ImportImage')
if(!$LockFile.Exists())
{
    
}
else {
    return "Another instance running.. wont do anything"
}

$container = $sa|Get-AzStorageContainer -name $StorageBlob
$Importqueue = $sa|Get-AzStorageQueue|?{$_.name -eq $QueueItem}
if(!$Importqueue)
{
    Throw "Cannot find the importqueue '$QueueItem'"
}

#Import first message from messagequeue, and remove it from the queue
$invisibleTimeout = [System.TimeSpan]::FromMinutes(10)
$queueMessage = $Importqueue.CloudQueue.GetMessage($invisibleTimeout,$null,$null)
$ImportCount = [int]::Parse($queueMessage.AsString)
[void]$Importqueue.CloudQueue.DeleteMessageAsync($queueMessage)

# Write-Information $Importqueue.CloudQueue.ApproximateMessageCount

$LocalStorage = "$env:TEMP\Pic\$([guid]::NewGuid().Guid)" 
Write-Information "Getting faces"
$workers = @()
Get-RandomFace -OutputFolder $LocalStorage -Amount $ImportCount -Verbose -passthru|%{
    $AzName = "Import\$($_.name)"
    Write-Information "Uploading $($_.name) to blob '$($SA.StorageAccountName)':'$AzName'"
    $ref = $container.CloudBlobContainer.GetBlockBlobReference($AzName)
    $ref.Properties.ContentType = "application/octet-stream"
    $workers += $ref.UploadFromFileAsync($_.fullname)
}
while($false -in $workers.IsCompleted)
{
    Write-Information "Waiting for blobupload ($(@($workers|?{$_.iscompleted}).count)/$($workers.Count))"
    Start-Sleep -Milliseconds 500
}
gci $LocalStorage|remove-item -Force -Recurse

if($Importqueue.CloudQueue.ApproximateMessageCount -gt 0)
{
    Write-Information "Testing"
}
