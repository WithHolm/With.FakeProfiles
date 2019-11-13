function Initialize-PsAzFunctions {
    [CmdletBinding()]
    param (
        [System.IO.DirectoryInfo]$path = $pwd
    )
    
    begin {
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
        # @(
        #     @{
        #         Name=".PsAz"
        #         ItemType = "Directory"
        #     }
        #     @{
        #         Name="NugetRequirements.psd1"
        #         ItemType = "File"
        #     }
        # )|%{
        #     if(gci -Path $path.FullName -Filter $_.name)
        #     {
        #         Write-Verbose "Adding '$($_.name)' $($_.itemtype) for management"
        #         new-item -Path $path.FullName 
        #     }
        # }
        if(!$path.GetDirectories(".PsAz"))
        {
            Write-Verbose "Adding a .PsAz Directory for management"
            New-item -Path $path.FullName -Name ".PsAz" -ItemType Directory
        }

        if(!$path.GetFiles("NugetRequirements.psd1"))
        {
            Write-Verbose "Adding a NugetRequirements Config File"
            $Filecontents = @(
                "#Add Nugetpackcages with name=Version as provided from find-package.Wildcards are supported,"
                "#or via Find-package 'packagename'|Add-PsAzFunctionPackage"
                "@{"
                ""
                "}"
            )
            New-item -Path $path.FullName -Name "NugetRequirements.psd1" -ItemType File -Value ($Filecontents -join "`n")
            # @(@{Cronos = "*"})|%{

            # }
        }
    }
    
    end {
        
    }
}