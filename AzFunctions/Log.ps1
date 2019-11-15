function write-LogInformation {
    [CmdletBinding()]
    param (
        [string]$Message,
        [switch]$ForceShow
    )
    
    begin {
        
    }
    
    process {
        Write-LogLine -Type Information -Callstack ((Get-PSCallStack)[1]) -message $Message
        # Suspend-FunctionLogging
    }
    
    end {
        
    }
}

function Set-FunctionLogging {
    [CmdletBinding()]
    param (
        [bool]$Enabled = $true
    )
    
    begin {
        initLog
        $ScriptPath = (Get-PSCallStack)[1].ScriptName
    }
    
    process {
        if($Enabled)
        {
            if($Global:EnableLog.Contains($ScriptPath))
            {
                $Global:EnableLog.Remove($ScriptPath)
            }
        }
        else 
        {
            $Global:EnableLog+=$ScriptPath
        }
    }
    
    end {
    }
}

function initLog
{
    if([string]::IsNullOrEmpty($Global:LogSuspension))
    {
        $Global:EnableLog = @()
    }
}

function Write-LogLine {
    [CmdletBinding()]
    param (
        [ValidateSet("Information")]
        [String]$Type,
        [string]$message,
        [System.Management.Automation.CallStackFrame]$Callstack

    )
    
    begin {
        initLog
        if(!$Global:EnableLog.Contains($ScriptPath))
        {
            return
        }
    }
    
    process {
        $LoggingName = $Callstack.Command 
        switch($type)
        {
            "Information"{
                Write-Information "$loggingName`: $message"
            }
        }
        
    }
    
    end {
        
    }
}

# ([System.IO.FileInfo]$PSScriptRoot).Directory.Parent.FullName