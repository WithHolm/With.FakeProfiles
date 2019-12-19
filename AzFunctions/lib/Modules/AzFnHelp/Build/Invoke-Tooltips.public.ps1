function Invoke-Tooltips {
    [CmdletBinding()]
    param (
        [string]$scope,
        [hashtable]$Variables
    )
    
    begin {
        $Variables.keys|%{
            Write-debug "Setting local variable '$_'"
            Set-Variable -Name $_ -Value $Variable.$_ -Scope local
        }
    }
    
    process {
        $tooltips = $Build_Function.tooltips
        $UsingTooltips = $tooltips.Keys|?{$tooltips.$_.scope -like $scope -and $tooltips.$_.Triggered -ne $true}
        $UsingTooltips|%{
            Write-Verbose "Checking tooltip rule '$_'"
            $tests = @($tooltips.$_.rules|%{
                try{
                    $Result = [bool]($_.command.invoke())
                }
                catch{
                    $result = $false
                }
                Write-Debug "Rule '$($_.name)': $result"
                # Write-Debug "Result was '$Result'" 
                @{$_=$Result}
            }
            )

            if($tests.values -notcontains $false)
            {
                if(![string]::IsNullOrEmpty($tooltips.$_.Triggered))
                {
                    $tooltips.$_.Triggered = $true
                }

                if($Build_Function.TooltipPreference -eq "Continue")
                {
                    Write-Warning $tooltips.$_.message
                }
                elseif($Build_Function.TooltipPreference -eq "Stop")
                {
                    Write-Error $tooltips.$_.message
                }
            }
            else 
            {
                Write-Verbose "Rule did not complete, returned false on $(($tests.keys|?{$tests.$_ -eq $false}) -join ", ")"
            }
        }
    }
    
    end {
        
    }
}