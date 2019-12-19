function Get-SingletonID {
    [CmdletBinding()]
    param (
        [Switch]$ReturnRunID
    )
    
    begin {
        
    }
    
    process {
        if($ReturnRunID)
        {
            $InstanceID = Get-SingletonID
            return $Script:RunID
        }
        else
        {
            $Ticks = [datetime]::Now.Ticks
            if ([string]::IsNullOrEmpty($Script:RunID))
            {
                $Script:RunID = [guid]::NewGuid().Guid.Replace("-", "")
            }
            # $_RunID = $Script:RunID
            $Ticks = [datetime]::Now.Ticks
            $RandomNumber = Get-random -Maximum 999999 -Minimum 0
            $ID = "$Script:RunID-$Ticks-$RandomNumber"
            if ([string]::IsNullOrEmpty($Script:InstanceID))
            {
                $Script:InstanceID = $ID
            }
            return $Script:InstanceID
        }
    }
    
    end {
        
    }
}