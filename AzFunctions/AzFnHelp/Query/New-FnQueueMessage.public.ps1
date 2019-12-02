using namespace Microsoft.Azure.Storage
function New-FnQueueMessage {
    [CmdletBinding()]
    param (
        [object[]]$Data,
        [Switch]$Encoded,
        [Microsoft.Azure.Storage.Queue.CloudQueue]$Queue,
        [timespan]$MessageLongevity
    )
    
    begin {
        
    }
    
    process {
        $Message = [Queue.CloudQueueMessage]::new($($data -join ''),$Encoded.IsPresent)
        # $Message.ExpirationTime
        if($MessageLongevity)
        {
            [void]$Queue.AddMessageAsync($Message,$MessageLongevity,([timespan]::Zero),$null,$null)
        }
        else {
            [void]$Queue.AddMessageAsync($Message)
        }
    }
    
    end {
    }
}
