using namespace System.Net
using namespace Microsoft.Azure
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param(
    $Request, 
    $TriggerMetadata 
)

$Body = [ordered]@{
    TimeStamp = [datetime]::Now
    message = "Error with http request"
}
$response = ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::BadRequest
    Body       = $Body
})
Write-Host "PowerShell HTTP trigger function processed a request."
import-module "az.storage"


try{
    if($Request.method -eq "Get")
    {
        $cs = [Microsoft.Azure.Cosmos.Table.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
        [Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($cs.TableEndpoint,$cs.Credentials)
        [Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference("Jobs")
        [void]$Table.CreateIfNotExists()
        $Table.
        $ProgressEntity = Get-AzTableRow -Table $Table
        $body = [ordered]@{
            Import = [ordered]@{
                Total = $(@($ProgressEntity|?{$_.PartitionKey -eq 'Import'}).count)
                NotCompleted = $(@($ProgressEntity|?{$_.PartitionKey -eq 'Import' -and $_.finished -eq $false}).count)
                Completed = $(@($ProgressEntity|?{$_.PartitionKey -eq 'Import' -and $_.finished -eq $true}).count)
            }
            Scale = [ordered]@{
            
            }

        }
        $ReturnStatus = [HttpStatusCode]::Accepted
    }
    elseif ($Request.method -eq "Post")
    {
        [Microsoft.Azure.Storage.cloudstorageaccount]$CS = [Microsoft.Azure.Storage.cloudstorageaccount]::Parse($env:AzureWebJobsStorage)
        if([string]::IsNullOrEmpty($Request.Query.Count))
        {
            $response.StatusCode = [HttpStatusCode]::BadRequest
            $response.Body.message = "Please pass count in query string"
        }
        else 
        {
            $Queue = Get-FnQueryFast -Connectionstring $env:AzureWebJobsStorage -Name "imgimportstart" -CreateIfNotExist
            # $QueueClient = [Queue.CloudQueueClient]::new($cs.QueueStorageUri,$CS.Credentials)
            # $Queue = $QueueClient.GetQueueReference('imgimportstart')
            # $Queue.CreateIfNotExists()
            # $count
            New-FnQueryMessage -Data $Request.Query.Count -Queue $Queue
            # $Message = [Queue.CloudQueueMessage]::new($Request.Query.Count)
            # $Message
            # [void]$Queue.AddMessageAsync($Message)
            $response.StatusCode = [HttpStatusCode]::Accepted
            $response.Body.message = "Added $($Request.Query.Count) pictures to importlist"
        }
    }
}
catch{
    $Body = [ordered]@{
        TimeStamp = [datetime]::Now
        message = "Error with http request: $_"
    }
    $response = ([HttpResponseContext]@{
        StatusCode = [System.Net.HttpStatusCode]::ServiceUnavailable
        Body       = $Body
    })
}
# $Action = 
# Interact with query parameters or the body of the request.
# $name = $Request.Query.Name
# if (-not $name)
# {
#     $name = $Request.Body.Name
# }

# if ($name)
# {
#     $status = [HttpStatusCode]::OK
#     $body = "Hello $name"
# }
# else
# {
#     $status = [HttpStatusCode]::BadRequest
#     $body = "Please pass a name on the query string or in the request body."
# }

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value $response
