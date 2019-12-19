using namespace System.Net
using namespace Microsoft.Azure
using namespace Microsoft.Azure.Storage
# using namespace Microsoft.Extensions.Configuration
# using namespace Microsoft.Extensions.Configuration.AzureAppConfiguration
# Input bindings are passed in via param block.
param(
    [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]$Request, 
    [hashtable]$TriggerMetadata,
    $starter
)

ipmo (join-path (split-path $PSScriptRoot) "AzFnHelp") -Force
$Body = [ordered]@{
    TimeStamp = [datetime]::Now
    message = "Error with http request"
}
$StatusCode = [System.Net.HttpStatusCode]::BadRequest
Write-Host "PowerShell HTTP trigger function processed a request."

# gci env:
$JobTable = Get-FnTableFast -Name "jobs" -Connectionstring $env:AzureWebJobsStorage -CreateIfNotExist
if($Request.Method -eq "GET")
{

    if($Request.Query.id -eq "All")
    {
        $ret = Get-AzTableRow  -Table $JobTable -CustomFilter "PartitionKey eq 'GenerateImage'"
    }
    elseif(![string]::IsNullOrEmpty($Request.Query.id))
    {
        Write-Information "Getting Info in job $($Request.Query.ID)"
        $ret = Get-AzTableRow -Table $JobTable -CustomFilter "RowKey eq '$($Request.Query.ID)' or Parent eq '$($Request.Query.ID)'"
    }
    else {
        $Body = [ordered]@{
            TimeStamp = [datetime]::Now
            message = "OK"
        }
    }

    # [string]::IsNullOrEmpty($ret)
    if(![string]::IsNullOrEmpty($ret))
    {
        $Body = $ret|Convertfrom-FnTableEntity|Group-Object tag,comment,parent
    }

    $StatusCode = [System.Net.HttpStatusCode]::OK
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $StatusCode
        Body       = $Body
    })
}
elseif($Request.Method -eq "POST") {
    
    if($Request.Query.Count)
    {
        Write-Information "Adding $($Request.Query.Count) to jobtable"
        $ID = [Guid]::NewGuid().Guid
        $Property = @{
            Parent = "Request: $($Request.Query.Count)"
            Comment = "Waiting"
            Value = [int]$Request.Query.Count
            Children = ""
            Tag = "Waiting"
            Completed = $false
        }
        [void](Add-AzTableRow -PartitionKey "GenerateImage" -RowKey $ID -property $Property -Table $JobTable)

        $Q = Get-FnQueueFast -CreateIfNotExist -Connectionstring $env:AzureWebJobsStorage -Name 'generateimage'
        New-FnQueueMessage -Queue $q -Data $id

        $Body = [ordered]@{
            TimeStamp = [datetime]::Now
            ID = $ID
            message = "Added request to generate $($Request.Query.Count) images"
        }
        $StatusCode = [System.Net.HttpStatusCode]::OK
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = $Body
        })
        # Invoke-Command -ScriptBlock {Invoke-WebRequest -Uri "http://myurl.com" -Method Post} -AsJob
    }
}