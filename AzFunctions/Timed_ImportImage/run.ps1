using namespace Cronos
# Input bindings are passed in via param block.
param($Timer)


##Singleton issue:
#https://github.com/Azure/azure-functions-host/issues/912
# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$Timer = [System.Diagnostics.Stopwatch]::StartNew()


import-module "az.storage"
$StorageBlob = "pictures"

#Loading 
. "$PSScriptRoot\getprofilepictures.ps1"


$cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
$sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
$Progresstable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName $ProgresstableName
$LockQueue = $sa|Get-AzStorageQueue|?{$_.name -eq $QueueItem}


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