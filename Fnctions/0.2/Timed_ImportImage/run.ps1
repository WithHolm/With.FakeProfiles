using namespace System.Net
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param($Timer)
import-module "az.storage"
# . (Join-Path ([System.IO.FileInfo]$PSScriptRoot).Directory.FullName "Log.ps1")
. "$PSScriptRoot\getprofilepictures.ps1"
# Set-FunctionLogging -enabled $true
##Singleton issue:
#https://github.com/Azure/azure-functions-host/issues/912
# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Information "PowerShell timer is running late!"
}

#INIT
$EndSecondsBuffer = 20
$MaxTime = ($Timer.ScheduleStatus.Next - $Timer.ScheduleStatus.Last)
$Finishby = [datetime]::Now.ToUniversalTime().AddSeconds($maxtime.TotalSeconds)
$TotalMintues = [math]::round($MaxTime.totalminutes)
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
# $ConfigTable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName "Config"



# Write an information log with the current time.
Write-Information "PowerShell THIS timer trigger function ran! TIME: $currentUTCtime. will process untill $($Finishby.AddSeconds(-$EndSecondsBuffer))"

$ImportEntitys = @(Get-AzTableRow -Table $Progresstable -CustomFilter "PartitionKey eq 'ImportImage' and Finished eq false and Count lt $maxbatchprocess")

$TotalImages = $(($ImportEntitys|%{$_.count}|measure -Sum).sum)
$SecondsLeft = $([math]::round(($Finishby - [datetime]::UtcNow).TotalSeconds))
Write-Information "Found $($ImportEntitys.count) entities. ($TotalImages) images. Processing for $SecondsLeft seconds"
# Write-information "processing as many as i can in $([math]::Round(($Finishby - [datetime]::UtcNow).totalseconds)) seconds"

[void](new-item -ItemType Directory -Path $LocalStorage -Force)
$workers = @()
:Import for ($i = 0; $i -lt @($ImportEntitys).Count; $i++)
{
    $SecondsLeft = $([math]::round(($Finishby - [datetime]::UtcNow).TotalSeconds))
    Write-Information "$SecondsLeft sec: Getting $($ImportEntitys[$i].count) items from thispersondoesnotexist"
    #Call thispersondoesnotexist
    Get-RandomFace -OutputFolder $LocalStorage -Amount $ImportEntitys[$i].count -Verbose -passthru|%{

        $BlobName = "Import\$($_.name)"
        Write-Debug "Uploading $($_.name) to blob '$($SA.StorageAccountName)':'$BlobName'"

        #Get Blobreference
        $ref = $container.CloudBlobContainer.GetBlockBlobReference($BlobName)

        #Set Blob ContentType
        $ref.Properties.ContentType = "application/octet-stream"

        #Upload to Blobstorage
        $workers += $ref.UploadFromFileAsync($_.fullname)
    }
    

    $UpdateProperties = @{}
    $ImportEntitys[$i].psobject.properties|?{$_.name -notin @("etag","tabletimestamp","Rowkey","partitionkey")}|%{
        $UpdateProperties.$($_.name) = $_.value
    }
    $UpdateProperties.finished = $true
    $UpdateEntity = "$($ImportEntitys[$i].partitionkey)/$($ImportEntitys[$i].Rowkey)"
    Write-Debug "update $UpdateEntity`: $($updateproperties|convertto-json -compress)"

    #Update progresstable - import
    $TableRowParam = @{
        Table = $Progresstable
        PartitionKey = $ImportEntitys[$i].partitionkey
        RowKey = $ImportEntitys[$i].Rowkey
        property = $UpdateProperties
        UpdateExisting = $true
    }
    [void](Add-AzTableRow @TableRowParam)

    #Create progresstable - Scale
    $TableRowParam = @{
        Table = $Progresstable
        PartitionKey = "Scale"
        RowKey = $_.name
        property = @{
            Source = "ScaleImage"
            Count = 1
            Finished = $false
        }
    }
    [void](Add-AzTableRow @TableRowParam)

    #Create progresstable - Face
    $TableRowParam = @{
        Table = $Progresstable
        PartitionKey = "Scale"
        RowKey = $_.name
        property = @{
            Source = "ScaleImage"
            Count = 1
            Finished = $false
        }
    }
    [void](Add-AzTableRow @TableRowParam)



    if([datetime]::UtcNow.AddSeconds($EndSecondsBuffer) -gt $Finishby)
    {
        $SecondsLeft = $([math]::round(($Finishby - [datetime]::UtcNow).TotalSeconds))
        Write-Information "Ending run wit $($workers.Count) items. $SecondsLeft seconds to spare. had $TotalMintues minutes"
        break :Import
    }
}

while($false -in $workers.IsCompleted)
{
    $Workersleft = $(@($workers|?{$_.iscompleted}).count)
    Write-Information "End: Waiting for blobupload ($Workersleft/$($workers.Count))"
    Start-Sleep -Milliseconds 500
}

remove-item $LocalStorage -Force -Recurse