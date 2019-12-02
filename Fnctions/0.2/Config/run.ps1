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
$StatusCode = [System.Net.HttpStatusCode]::BadRequest

Write-Host "PowerShell HTTP trigger function processed a request."
import-module "az.storage"


try{

    if($Request.method -eq "Get")
    {
        $cs = [Microsoft.Azure.Cosmos.Table.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
        [Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($cs.TableEndpoint,$cs.Credentials)
        [Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference("config")
        [void]$Table.CreateIfNotExists()
        $Body = @{}
        $rows = Get-AzTableRow -Table $Table
        $rows|select-object -Unique PartitionKey|%{
            Write-Information "Create '$($_.PartitionKey)'"
            $Body.$($_.PartitionKey) = @{}
        }
        Foreach($row in $rows)
        {
            $Body.$($row.PartitionKey).$($row.rowkey) = $($row.value|ConvertFrom-Json)
        }
        $StatusCode = [System.Net.HttpStatusCode]::Accepted
    }
    elseif ($Request.method -eq "Post")
    {
    }
}
catch{
    $_|fl * -force
    $Body = [ordered]@{
        TimeStamp = [datetime]::Now
        message = "Error with http request: $_"
    }
    $StatusCode = [System.Net.HttpStatusCode]::ServiceUnavailable
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
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $Body
})
