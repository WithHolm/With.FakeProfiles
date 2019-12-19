using namespace System.Net
using namespace Microsoft.Azure
using namespace Microsoft.Azure.Storage


Get-ChildItem $PSScriptRoot -Filter "*Public.ps1" -Recurse|%{
    . $_.FullName
}

