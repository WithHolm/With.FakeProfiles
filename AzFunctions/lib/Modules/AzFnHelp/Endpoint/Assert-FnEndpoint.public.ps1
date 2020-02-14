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
        if(![string]::IsNullOrEmpty($Global:Build_Function))
        {
            $CallingScriptFile = [System.IO.FileInfo](Get-PSCallStack)[1].ScriptName
            Write-Host "Endpoint Scriptfile is $CallingScriptFile"
        }
    }
    
    process {
        if([string]::IsNullOrEmpty($Global:Build_Function))
        {
            return $null
        }
        $this = [ordered]@{
            # EndpointName = $FunctionName
            scriptFile = $Global:Build_Function.ModulePath
            entryPoint = ""
            bindings = @()
        }
        if($Disabled)
        {
            disabled = $Disabled.IsPresent
        }
        if($excluded)
        {
            excluded = $Excluded.IsPresent
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