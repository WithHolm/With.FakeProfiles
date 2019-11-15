function Add-NugetDependencies {
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
        


        Write-verbose "Adding a solution file"
        $SolutionFolder = (Join-Path $Script:AzFunctionsTemp "Solution")
        if(test-path $SolutionFolder)
        {
            Remove-item -Path $SolutionFolder -Recurse
        }

        dotnet new classlib -n 'dummy' -o $SolutionFolder

        #Import Dev set nuget dependencies
        [hashtable]$psd1 = Import-PowerShellDataFile -Path (Join-path $Script:AzFunctionsRoot 'NugetRequirements.psd1')
        
        #Add Dependencies set by this solution
        $dep = @{
            Cronos = "*"
        }

        $dep.keys|%{
            if(!$psd1.ContainsKey($_))
            {
                $psd1.$_ = $dep.$_
            }
            else {
                #If dev 
                if($psd1.$_ -ne $dep.$_)
                {
                    Write-warning "There is a mismatch on package '$_', User set version:$($psd1.$_), PSAzFunctions set version:$($psd1.$_). Will keep highest version"
                }
            }
        }


    }
    
    end {
        
    }
}