function Assert-FnEndpoint {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [String]$FunctionName,
        [scriptblock]$bindings,
        [switch]$Disabled,
        [switch]$Excluded
    )
    
    begin {
        if([string]::IsNullOrEmpty($Global:Build_Function))
        {
            return $null
        }
        
        $CallingScriptFile = [System.IO.FileInfo](Get-PSCallStack)[1].ScriptName
        Write-Host "Endpoint Scriptfile is $CallingScriptFile"
    }
    
    process {
        $this = [ordered]@{
            # EndpointName = $FunctionName
            Scriptfile = $Global:Build_Function.ModulePath
            entrypoint = ""
            bindings = @()
            Disabled = $Disabled.IsPresent
            Excluded = $Excluded.IsPresent
        }

        #Get EntryPoint
        $SB = [scriptblock]::Create((Get-content $CallingScriptFile.FullName -Raw))
        # (Get-PSCallStack)[1].InvocationInfo
        $EntryPoint = $SB.Ast.EndBlock.statements|%{
            if($_.extent.Text -like "Function *")
            {
                $_.name
            }
        }

        if([string]::IsNullOrEmpty($EntryPoint))
        {
            Throw "Could not find Entrypoint for function"
        }

        $this.entrypoint = $EntryPoint



        $Global:Build_Function.Functions.$FunctionName = $this

        $this.bindings = $bindings.Invoke()
        # $B = $bindings.Invoke()

    }
    
    end {
        
    }
}