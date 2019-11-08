param(
    [validateset("Run","Sync")]
    $Action = "Run"
)
function Format-StringModern {
    [CmdletBinding()]
    param (
        [string]$InputString,
        $object
    )
    
    begin {
        
    }
    
    process {
        # Write-Verbose "Input = $InputString"
        [regex]::Matches($InputString,"([{].*?[}])")|ForEach-Object{
            $Key = $_.value.substring(1,$_.length-2)
            # Write-verbose "Key is $key"
            if($key.StartsWith("CMD:",[System.StringComparison]::InvariantCultureIgnoreCase))
            {
                $value = invoke-expression -Command $key.substring(4)
            }
            else {
                $value = $object
                $key.split(".")|ForEach-Object{
                    $value = $value.$_
                }
            }
            $Inputstring = $Inputstring.Replace($_,($value).tostring()) 
        }
        return $InputString
    }
    
    end {
        
    }
}

Properties{
    $Options = Import-PowerShellDataFile -Path "$PSScriptRoot\Options.psd1"
    $Pipeline = $options.Project.Pipeline 
    $FormatStringRefObject = @{
        Action = $Action
        Pipeline=$Pipeline
        Options=$options
    }
    $AutomationAccountName = Format-StringModern -InputString $options.az.resources.AutomationAccount.name  -object $FormatStringRefObject
    $ResourcegroupName = Format-StringModern -InputString $options.az.resources.ResourceGroup.name  -object $FormatStringRefObject
}

Task default -depends ImportVariables

Task ImportVariables {
    Write-Output ""
    $AAccount = Get-AzAutomationAccount -ResourceGroupName $ResourcegroupName -Name $AutomationAccountName
    $AAccount|Get-AzAutomationVariable|select LastModifiedTime,Description,Name,Value
}

Task ImportEnviromentVariables {

}