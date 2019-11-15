function Initialize-PsAzFunctions {
    [CmdletBinding()]
    param (
        [System.IO.DirectoryInfo]$path = $Script:AzFunctionsRoot
    )
    
    begin {
        if([String]::IsNullOrEmpty($path.FullName))
        {
            Throw "A path for -path was not defined"
        }
        Write-verbose "Path is $($path.fullname)"
        $path = [System.IO.DirectoryInfo]$path.FullName
        @("Host.json","requirements.psd1","local.settings.json","profile.ps1")|%{
            Write-Verbose "Checking for $_ file"
            if(!$path.GetFiles($_))
            {
                Throw "Could not find a $_ at path $($path.FullName)"
            }
        }

    }
    
    process {
        if(!(test-path $Script:AzFunctionsTemp))
        {
            Write-Verbose "Adding a .PsAz Directory for management"
            New-item -Path $Script:AzFunctionsTemp -ItemType Directory
        }

        if(!$path.GetFiles("NugetRequirements.psd1"))
        {
            Write-Verbose "Adding a NugetRequirements Config File"
            $Filecontents = @(
                "#Add Nugetpackcages with name=Version as provided from find-package.Wildcards are supported,"
                "#or via Find-package 'packagename'|Add-PsAzFunctionPackage"
                "@{"
                "`tCronos = '*'"
                "}"
            )
            New-item -Path $path.FullName -Name "NugetRequirements.psd1" -ItemType File -Value ($Filecontents -join "`n")
        }
    }
    
    end {
        
    }
}