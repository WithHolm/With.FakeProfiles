$InformationPreference = "Continue"
#Requires -modules Az.Storage, Az.Resources
Get-ChildItem "$PSScriptRoot\Modules" -Directory|%{
    Write-host "Loading module $($_.name)"
    ipmo $_.FullName -Force
}

#FFA

Write-Verbose "Adding Cmdlets"
Gci -Recurse "$PSScriptRoot\function" -Include "*.function.ps1", "*.public.ps1"|%{
    . $_.FullName
}
