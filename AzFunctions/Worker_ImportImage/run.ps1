using namespace Microsoft.Azure.Storage

# Input bindings are passed in via param block.
param([string] $QueueItem, $TriggerMetadata)

import-module "az.storage"
$StorageBlob = "pictures"

. "$PSScriptRoot\getprofilepictures.ps1"

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
# $TriggerMetadata

$cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
$sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
$container = $sa|Get-AzStorageContainer -name $StorageBlob
$Importqueue = $sa|Get-AzStorageQueue|?{$_.name -eq $QueueItem}
# $JobTable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -TableName "Jobs" -storageAccountName $sa.StorageAccountName

$invisibleTimeout = [System.TimeSpan]::FromMinutes(10)
$queueMessage = $Importqueue.CloudQueue.GetMessage($invisibleTimeout,$null,$null)
$ImportCount = $queueMessage.AsString
[void]$Importqueue.CloudQueue.DeleteMessageAsync($queueMessage)
# Write-Information "BatchSize is $QueueItem"


$LocalStorage = "$env:TEMP\Pic\$([guid]::NewGuid().Guid)" 
Write-Information "Getting faces"
$workers = @()
Get-RandomFace -OutputFolder $LocalStorage -Amount $ImportCount -Verbose -passthru|%{
    $AzName = "Import\$($_.name)"
    Write-Information "Uploading $($_.name) to blob '$($SA.StorageAccountName)':'$AzName'"
    $ref = $container.CloudBlobContainer.GetBlockBlobReference($AzName)
    $ref.Properties.ContentType = "application/octet-stream"
    $workers += $ref.UploadFromFileAsync($_.fullname)
    # new-aztablero
    # $SAItem = ($sa|Set-AzStorageBlobContent -File $_ -Container $StorageBlob -Blob "Import\$(Split-Path $_ -Leaf)" -Force)
    # remove-item $_
}
while($false -in $workers.IsCompleted)
{
    Write-Information "Waiting for blobupload ($(@($workers|?{$_.iscompleted}).count)/$($workers.Count))"
    Start-Sleep -Milliseconds 500
}
gci $LocalStorage|remove-item -Force -Recurse