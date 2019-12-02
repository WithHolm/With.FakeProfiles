# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# $cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
# Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
# $sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
# $CloudStorageAccount = $sa.Context.StorageAccount
# # $container = $sa|Get-AzStorageContainer -name $StorageBlob

# [Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($CloudStorageAccount.TableEndpoint,$CloudStorageAccount.Credentials)
# [Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference($TableName)
# $table = Get-AzTableTable -storageAccountName $sa.StorageAccountName -TableName $TableName -resourceGroup $sa.ResourceGroupName

# # Write an information log with the current time.
# Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
