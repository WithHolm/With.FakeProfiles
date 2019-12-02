using namespace System.Net
using namespace Microsoft.Azure
using namespace Microsoft.Azure.Storage

#Requires -modules Az.Storage, Az.Resources
Get-ChildItem $PSScriptRoot -Filter "*Public.ps1" -Recurse|%{
    . $_.FullName
}