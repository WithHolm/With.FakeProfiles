using namespace System.Net
using namespace System.io
using namespace Microsoft.Azure.Storage
# Input bindings are passed in via param block.
param(
    [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]$Request, 
    [hashtable]$TriggerMetadata,

    #Default values
    $ProgresstableName = "Progress",
    $ReturnStatus = ([System.Net.HttpStatusCode]::BadRequest),
    $returnMessage = "Error with http request"
)

import-module "az.storage"



$cs = [Microsoft.Azure.Cosmos.Table.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
[Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($cs.TableEndpoint,$cs.Credentials)
[Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference($ProgresstableName)

$ProgressEntity = Get-AzTableRow -Table $Table
try{
    if ($Request.method -eq "Get")
    {
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
    #New Item
    elseif($Request.method -eq "Post")
    {
        if([String]::IsNullOrEmpty($Request.Query.ID))
        {
            $Body.message 
        }
        else 
        {
            
        }
        @(
            "ID"
        ) 
        $Entity = $Request.Body|ConvertFrom-Json
        if([string]::IsNullOrEmpty($entity.Partition))
        {

        }


        if($entity -is [array])
    }
    #Update Item
    elseif($Request.method -eq "Put")
    {
        $Entity = $Request.Body|ConvertFrom-Json
        if($entity -is [array])
    }
}catch{
    $Body = [ordered]@{
        TimeStamp = [datetime]::Now
        message = "Error with http request"
    }
    $response = ([HttpResponseContext]@{
        StatusCode = [System.Net.HttpStatusCode]::ServiceUnavailable
        Body       = $Body
    })
}


# $ImportEntitys = Get-AzTableRow -Table $Table
# $status = [HttpStatusCode]::Accepted
# # $body = [ordered]@{
#     ImportImage = [ordered]@{
#         Total = $(($ImportEntitys|?{$_.PartitionKey -eq 'ImportImage'}|ForEach-Object{$_.count}|Measure-Object -Sum).sum)
#         NotCompleted = $(($ImportEntitys|?{$_.PartitionKey -eq 'ImportImage' -and $_.finished -eq $false}|ForEach-Object{$_.count}|Measure-Object -Sum).sum)
#         Completed = $(($ImportEntitys|?{$_.PartitionKey -eq 'ImportImage' -and $_.finished -eq $true}|ForEach-Object{$_.count}|Measure-Object -Sum).sum)
#     }
# }
if(!$body)
{
    $Body = [ordered]@{
        TimeStamp = [datetime]::Now
        message = $returnMessage
    }
}

$response = ([HttpResponseContext]@{
    StatusCode = $ReturnStatus
    Body       = $Body
})

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value $response
