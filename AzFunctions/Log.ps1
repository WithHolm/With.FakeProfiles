function write-LogInformation {
    [CmdletBinding()]
    param (
        [string]$Message,
        [switch]$ForceShow
    )
    
    begin {
        
    }
    
    process {
        Write-LogLine -Type Information -Callstack (Get-PSCallStack|select -Skip 1) -message $Message
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
        # Write-host "Setting enablelog to $enabled for $ScriptPath"
    }
    
    process {
        if($Enabled -eq $true)
        {
            Write-host "Adding $ScriptPath to log allow list" 
            $Global:EnableLog+=$ScriptPath
        }
        else 
        {
            if($Global:EnableLog.Contains($ScriptPath))
            {
                $Global:EnableLog.Remove($ScriptPath)
            }
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
        [System.Management.Automation.CallStackFrame[]]$Callstack

    )
    
    begin {
        initLog
        Write-host "Is callstack enabled for log?"
        $Global:EnableLog|%{
            Write-host $_
        }
        Write-host ***
        $Log = $false
        $Callstack|%{
            # Write-host "checking $($_.ScriptName)"
            if(!$Global:EnableLog.Contains($_.ScriptName))
            {
                $Log = $true
                # return
            }
        }
    }
    
    process {
        if($log -eq $true)
        {
            $LoggingName = $Callstack.Command 
            switch($type)
            {
                "Information"{
                    Write-Information "$loggingName`: $message"
                }
            }
        }
        
    }
    
    end {
        
    }
}