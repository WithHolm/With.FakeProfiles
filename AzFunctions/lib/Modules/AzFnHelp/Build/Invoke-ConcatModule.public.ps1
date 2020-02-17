<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ModuleFilePath
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

function Invoke-ConcatModule {
    [CmdletBinding()]
    param (
        [System.IO.FileInfo]$ModuleFilePath
    )
    
    begin {
        # if(@(get-content $ModuleFilePath|?{$_ -like "region concat"}).count -eq 0)
        # {
        #     throw "A '#region concat' was not added. please read documentation of how to add this"
        # }
    }
    
    process {
        
    }
    
    end {
        
    }
}