function Add-NugetPackages {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        [void](dotnet --version)
        if($PSEdition -ne "Core")
        {
            throw "not dotnet core"   
        }
    }
    process {
        
    }
    
    end {
        
    }
}