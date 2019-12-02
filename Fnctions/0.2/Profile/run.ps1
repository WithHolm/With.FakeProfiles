using namespace System.Net
using namespace Microsoft.Azure
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param(
    $Request, 
    $TriggerMetadata
    # $action = $Request.query.Action    
)
# $k = [HttpResponseContext]::new()
# $k.StatusCode = [System.Net.HttpStatusCode]::BadRequest
$Body = [ordered]@{
    TimeStamp = [datetime]::Now
    message = "Error with http request"
}
$response = ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::BadRequest
    Body       = $Body
})
# $request | convertto-json
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
import-module "az.storage"
[Microsoft.Azure.Storage.cloudstorageaccount]$CS = [Microsoft.Azure.Storage.cloudstorageaccount]::Parse($env:AzureWebJobsStorage)
# [Microsoft.Azure.Storage.cloudstorageaccount]::Parse(

try{
    if ($Request.method -eq "Post")
    {

        if([string]::IsNullOrEmpty($Request.Query.Count))
        {
            $response.StatusCode = [HttpStatusCode]::BadRequest
            $response.Body.message = "Please pass count in query string"
        }
        else {
            [Queue.CloudQueueClient]$QueueClient = $cs.CreateCloudQueueClient()
            $Queue = $QueueClient.GetQueueReference('ImgImportStart')
            $Queue.CreateIfNotExists()
            $Message = [Queue.CloudQueueMessage]::new($count)
            $response.StatusCode = [HttpStatusCode]::Accepted
            $response.Body.message = "Added $count pictures to importlist"
        }



        # if ([string]::IsNullOrEmpty($Request.Query.Count) -or [string]::IsNullOrEmpty($Request.Query.Import))
        # {
        #     $ImportTable = "Import"
    
        #     $Count = $Request.Query.count
        #     if([string]::IsNullOrEmpty($Request.Query.count))
        #     {
        #         $count = 1
        #     }
        #     else{
        #         try{
        #             $count = [int]$count
        #         }
        #         catch{
        #             Write-verbose $_
        #             $count = 1
        #         }
        #     }
    
        #     Write-Verbose "Creating tableclient for account '$($CS.TableEndpoint)'"
        #     # [Microsoft.Azure.Storage.Auth]
        #     # [CloudQueue]::
        #     [Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($cs.TableEndpoint,$cs.Credentials)
        #     [Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference($ImportTable)
    
        #     Write-Information "Adding $count Profiles to be imported" 
        #     [void](Add-AzTableRow -Table $Table -PartitionKey "ImportImage" -RowKey $([guid]::NewGuid().Guid) -property @{Count=$count;Processed=$false;Source="Import"})

        #     $response.StatusCode = [HttpStatusCode]::Accepted
        #     $response.Body.message = "Added $count pictures to importlist"
        # }
        # else
        # {
        #     $status = [HttpStatusCode]::BadRequest
        #     $body = "Please pass count in query string"
        # }
    }
}
catch{
    $Body = [ordered]@{
        TimeStamp = [datetime]::Now
        message = "Error with http request"
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
