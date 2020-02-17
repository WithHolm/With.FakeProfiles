function Get-FunctionModule {
    [CmdletBinding()]
    param (
        $WorkingDirectory,
        [string[]]$Exclude,
        [String]$ModuleName
    )
    
    begin {
        
    }
    
    process {
        $param = @{
            path = $WorkingDirectory
            Filter = "*.psm1"
            Recurse = $true
            Exclude = $Exclude
        }
        #Get all files from WorkingPath that ends in .psm1 and is not THIS moudule 
        $ModuleFiles = Get-ChildItem @param
        
        if(![string]::IsNullOrEmpty($ModuleName))
        {
            $ModuleFiles = $ModuleFiles|?{$_.BaseName -like $ModuleName}
            # if(!$returnmodule)
            # {
            #     throw "Could not find module '$ModuleName'"
            # }
            # return $returnmodule|select -first 1
        }
        if(!$ModuleFiles)
        {
            throw "Could not find any modulefiles within path $"
        }
        return $ModuleFiles|select -first 1

    }
    
    end {
        
    }
}