$InformationPreference = "Continue"
#Requires -modules Az.Storage, Az.Resources
Get-ChildItem "$PSScriptRoot\Modules" -Directory|%{
    Write-host "Loading module $($_.name)"
    ipmo $_.FullName -Force
}

# ipmo "$PSScriptRoot\Modules\azfnhelp" -Scope Global

# Write-Verbose "Adding Models"
# $LoadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()
# $ref = @(
#     "Microsoft.Azure.Cosmos.Table"
#     "System.Management.Automation"
# )|%{
#     $lix = $_
#     ($LoadedAssemblies|?{$_.FullName -like "$lix*"}).Location
# }

# $ref|%{
#     Write-Information $_
# }

# Gci -Recurse "$PSScriptRoot\function" -filter "*.model.cs"|%{
#     Write-Information "Loading $($_.name)"
#     Add-Type -Path $_.FullName -ReferencedAssemblies $ref
# }

Write-Verbose "Adding Cmdlets"
Gci -Recurse "$PSScriptRoot\function" -Include "*.function.ps1", "*.public.ps1"|%{
    . $_.FullName
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
        $Request.Query
        $Request.Url
    }
    
    end {
        $Body = [ordered]@{
            TimeStamp = [datetime]::Now
            message = "Added request to generate yaas images"
        }
        $StatusCode = [System.Net.HttpStatusCode]::OK
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = $Body
        })
    }
}
