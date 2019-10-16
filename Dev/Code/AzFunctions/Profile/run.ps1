using namespace System.Net
# Input bindings are passed in via param block.
param(
    [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]$Request, 
    [System.Collections.Hashtable]$TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

if ($name) {
    $status = [HttpStatusCode]::OK
    $body = "Hello $name"
}
else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass a name on the query string or in the request body."
}

$body = Get-AzContext|ConvertTo-Json
# Write-Output $TriggerMetadata|gm

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
