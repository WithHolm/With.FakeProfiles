
gci $PSScriptRoot -Filter "*.public.ps1" -Recurse|%{
    . $_.FullName
}
$Script:AzFunctionsRoot = Split-path $PSScriptRoot -Parent
$Script:AzFunctionsTemp= join-path $Script:AzFunctionsRoot ".Temp"
Initialize-PsAzFunctions -path $Script:AzFunctionsRoot
