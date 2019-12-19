$InformationPreference = "Continue"
#Requires -modules Az.Storage, Az.Resources
Get-ChildItem "$PSScriptRoot\Modules" -Directory|%{
    ipmo $_.FullName
}

# ipmo "$PSScriptRoot\Modules\azfnhelp" -Scope Global

Write-Verbose "Adding Models"
$LoadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()
$ref = @(
    "Microsoft.Azure.Cosmos.Table"
    "System.Management.Automation"
)|%{
    $lix = $_
    ($LoadedAssemblies|?{$_.FullName -like "$lix*"}).Location
}

$ref|%{
    Write-Information $_
}

Gci -Recurse "$PSScriptRoot\function" -filter "*.model.cs"|%{
    Write-Information "Loading $($_.name)"
    Add-Type -Path $_.FullName -ReferencedAssemblies $ref
}

Write-Verbose "Adding Cmdlets"
Gci -Recurse "$PSScriptRoot\function" -Include "*.QTrigger.ps1","*.BlobTrigger.ps1","*.Http.ps1", "*.public.ps1"|%{
    . $_.FullName
}

