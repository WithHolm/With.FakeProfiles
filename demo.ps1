using namespace System.Net
using namespace Microsoft.Azure
using namespace Microsoft.Azure.Storage

$Key = "DefaultEndpointsProtocol=https;AccountName=devfakeprofilessa;AccountKey=wIOyeIJlo6hbnu//oQjYF6r5KId4qUArpOhcTkILfEMy+QZw1lXJ1eHxOraSXRNsFVUrWNS/gxhFZQz6c7y77A==;EndpointSuffix=core.windows.net"
[Microsoft.Azure.Storage.cloudstorageaccount]$CS = [Microsoft.Azure.Storage.cloudstorageaccount]::Parse($Key)
$QueueClient = [Queue.CloudQueueClient]::new($cs.QueueStorageUri,$CS.Credentials)

# [Queue.CloudQueueClient]$QueueClient = $cs.CreateCloudQueueClient()
$Queue = $QueueClient.GetQueueReference('imgimportstart')
@(1..10)|%{
    $Message = [Queue.CloudQueueMessage]::new($_)
    [void]$Queue.AddMessageAsync($Message)
}

Write-host "Starting demo" -ForegroundColor Green
@(1..10)|%{
    Start-Job -Name $_ -ScriptBlock {
        import-module Az.Storage
        [Microsoft.Azure.Storage.cloudstorageaccount]$CS = [Microsoft.Azure.Storage.cloudstorageaccount]::Parse($using:Key)
        $QueueClient = [Microsoft.Azure.Storage.Queue.CloudQueueClient]::new($cs.QueueStorageUri,$CS.Credentials)
        $Queue = $QueueClient.GetQueueReference('imgimportstart')
        start-sleep -Milliseconds (get-random -Minimum 200 -Maximum 1000)
        $k = $Queue.GetMessages(1,[timespan]::FromSeconds(5))
        start-sleep -Milliseconds (get-random -Minimum 200 -Maximum 1000)
        $k2 = $Queue.GetMessages(1,[timespan]::FromSeconds(5))
        if($k -and $k2)
        {
            Write-output "$($args[0]):$($k2.asstring)-$($k.AsString)"
        }
    } -ArgumentList $_
}|Receive-Job -Wait

Write-host "Demo Done" -ForegroundColor Green
# start-sleep 5
$Queue.ClearAsync()
# $K = $null
# while([string]::IsNullOrEmpty($K))
# {
#     $k = $Queue.GetMessages(1,[timespan]::FromSeconds(5))
# }
# # $Queue.CreateIfNotExists()
# # $Queue.FetchAttributes()
# # $Queue.ApproximateMessageCount
# $k
# $Message = [Queue.CloudQueueMessage]::new($count)
# $response.StatusCode = [HttpStatusCode]::Accepted
# $response.Body.message = "Added $count pictures to importlist"