function Build-FnEndpoints {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [System.IO.DirectoryInfo]$WorkingDirectory = $pwd.Path,
        [String]$ScriptFilter = '*.function.ps1',
        [string]$ModuleName,
        [ValidateSet("Continue","Silentlycontinue","Stop")]
        [string]$TooltipPreference = "Continue"
    )
    
    begin {
        
        Write-Verbose "Starting new build of $($WorkingDirectory.FullName)"

        if(!(test-path (join-path $WorkingDirectory.FullName '.\host.json')))
        {
            throw "The defined working path is not basepath of az function"
        }

        $Global:Build_Function = @{
            WorkingDirectory = $WorkingDirectory.FullName
            ModulePath = ""
            Hostconfig = Get-content (join-path $WorkingDirectory.FullName '.\host.json') -Raw|ConvertFrom-Json -Depth 99
            Functions = @{}
            TooltipPreference = $TooltipPreference
            tooltips = (Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "Tooltips.psd1"))
        }

        if($TooltipPreference -eq "stop")
        {
            $ErrorActionPreference = $TooltipPreference
        }

        # $Global:Build_Function.tooltips = 
    }
    
    process {
        $InformationPreference = "Continue"
        #Get all files from WorkingPath that ends in .psm1 and is not THIS moudule 
        $ModuleFiles = gci $WorkingDirectory.FullName -Filter "*.psm1" -Recurse -Exclude 'AzFnHelp*'

        #If there are several modules avalible and modulename is not defined
        if(@($ModuleFiles).count -gt 1 -and [String]::IsNullOrEmpty($ModuleName))
        {
            Throw "Found several modules. Please define -ModuleName 'YourFunctionModule'. '$($WorkingDirectory.FullName)'"
        }
        #Else if modulename is defined and 
        elseif(@($ModuleFiles).count -gt 1 -and ![String]::IsNullOrEmpty($ModuleName)) 
        {
            $ModuleFiles = $ModuleFiles|?{$_.BaseName -like $ModuleName}
            if(!$ModuleFiles)
            {
                Throw "Could not find any ModuleFiles with the name like '$ModuleName'"
            }
            elseif(@($ModuleFiles).count)
            {
                Throw "Found several modulefiles with the name '$ModuleName': $($ModuleFiles.name -join ', ')"
            }
        }

        #Modulefiles is just 1 instance and probably correct
        #c:\dir\dir\azfunction\lib\module.psm1 -> "../lib/Module.psm1"
        $Global:Build_Function.ModulePath = "..$($ModuleFiles.FullName.Replace($WorkingDirectory.FullName,'').replace("\","/"))"

        Foreach($File in (gci $WorkingDirectory.FullName -Recurse -Filter $ScriptFilter))
        {
            Write-Information "Building Endpoint defined in file '$($file.name)'"
            &$File.fullname
        }

        Write-verbose "Removing previously created endpoints"
        #Get directories that have a defined function.json
        $RemDir = Get-ChildItem $WorkingDirectory.FullName -Directory|?{gci $_.FullName -Filter "function.json"}
        $RemDir|%{
            if($ModuleFiles.FullName -like "*$($_.FullName)*")
            {
                throw "$($_.FullName) is part of the module directory path $($ModuleFiles.fullname). throwing as it would delete this path. Have you defined function.json inside module folder?"
            }
            Write-Debug "Removing $_"
            $_|Remove-Item -Force -Recurse
        }

        $Global:Build_Function.Functions.keys|%{
            $FuncDirPath = (join-path $Global:Build_Function.WorkingDirectory $_)
            if(test-path $FuncDirPath)
            {
                Write-Error "There is a folder named '$($_)' already and is not a function folder. please fix the name of the folder or the endpoint"
            }
            else {
                Write-Information "Creating folder for '$_'"
                $FuncDir = New-item -Path $Global:Build_Function.WorkingDirectory -Name $_ -ItemType Directory
                [void](New-Item -Path $FuncDir.FullName -Name "Function.json" -ItemType File -Value ($Global:Build_Function.Functions.$_|ConvertTo-Json -Depth 99))
            }
            # New-item $fun
        }
        # if([string]::IsNullOrEmpty($Global:Build_Function.ModulePath))
        # {
        #     $modulepath = $CallingScriptFile.Directory
        #     while(!(gci $modulepath.FullName -Filter "*.psm1"))
        #     {
        #         if(gci $modulepath.FullName -Filter "host.json")
        #         {
        #             throw "Found Host.json before finding modulefile for solution... is it created?"
        #         }
        #         $modulepath = $modulepath.Parent
        #     }
        #     $Global:Build_Function.ModulePath = (gci $modulepath.FullName -Filter "*.psm1").FullName
        # }

        # if([string]::IsNullOrEmpty($Global:Build_Function.FunctionPath))
        # {
        #     $modulepath = $CallingScriptFile.Directory
        #     while(!(gci $modulepath.FullName -Filter "host.json"))
        #     {
        #         $modulepath = $modulepath.Parent
        #     }
        #     $Global:Build_Function.ModulePath = (gci $modulepath.FullName -Filter "*.psm1").FullName
        # }
    }
    
    end {
    }
}