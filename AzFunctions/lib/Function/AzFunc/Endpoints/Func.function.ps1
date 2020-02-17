Assert-FnEndpoint -FunctionName "Test" -bindings {
    Assert-FnHttpBinding -In -Methods Get,Post #-Route "test/{Id:int}"
    Assert-FnHttpBinding -Out
}
function Test-fun {
    [CmdletBinding()]
    param (
        [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]$Request, 
        [hashtable]$TriggerMetadata
    )
    
    begin {
        
    }
    
    process {
        $Id
        $Request.Query
        $Request.Url
    }
    
    end {
        Push-OutputBinding -Name OutputBinding -Value "output"
    }
}