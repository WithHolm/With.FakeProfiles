# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

$EndSecondsBuffer = 20
$MaxTime = ($Timer.ScheduleStatus.Next - $Timer.ScheduleStatus.Last)
$Finishby = [datetime]::Now.ToUniversalTime().AddSeconds($maxtime.TotalSeconds)
$TotalMintues = [math]::round($MaxTime.totalminutes)
$ProgresstableName = "Progress"
$StorageBlob = "pictures"

$cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
$SA = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
$container = $sa|Get-AzStorageContainer -name $StorageBlob
# $Queue = $sa|Get-AzStorageQueue|?{$_.name -eq $QueueName}
$Progresstable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName $ProgresstableName
# $ConfigTable = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName "Config"



# Write an information log with the current time.
Write-Information "PowerShell THIS timer trigger function ran! TIME: $currentUTCtime. will process untill $($Finishby.AddSeconds(-$EndSecondsBuffer))"
