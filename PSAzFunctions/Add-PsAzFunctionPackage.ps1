function Add-PsAzFunctionPackage {
    [CmdletBinding()]
    param (
        [parameter(ParameterSetName='Package',Mandatory,ValueFromPipeline)]
        [Microsoft.PackageManagement.Packaging.SoftwareIdentity]$package,
        [parameter(ParameterSetName='Manual',Mandatory)]
        [String]$Name,
        [parameter(ParameterSetName='Manual')]
        [String]$Version = "*"
    )
    
    begin {
        
    }
    
    process {
        if($PSCmdlet.ParameterSetName -eq "Manual")
        {
            $Package = Find-package $Name -AllVersions
            $UsingPackage = $Package|Where-Object{$_.Version -like $Version}|Sort-Object Version -Descending |select -first 1
            if(!$UsingPackage)
            {
                Throw "Could not find a package for $Name with version $Version. Avalible versions: $($Package.version -join ", ")"
            }
            $UsingPackage|Add-PsAzFunctionPackage
        }elseif ($PSCmdlet.ParameterSetName -eq "Package") {
            [void](dotnet --version)
            if($PSEdition -ne "Core")
            {
                throw "not dotnet core"   
            }
            if($script:PsAzFuncCsProj)
            {
                
            }
        }
    }
    
    end {
        
    }
}