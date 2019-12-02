#Im really unsure of this name... GET-{something}PEEK ?!..PLX FIX
function Get-FnQueuePeek {
    [CmdletBinding()]
    [outputtype([Microsoft.Azure.Storage.Queue.CloudQueueMessage[]])]
    param (
        [Microsoft.Azure.Storage.Queue.CloudQueue]$Queue,
        
        [ValidateRange(1,32)]
        [int]$count = 32
    )
    
    begin {
        
    }
    
    process {
        return @($queue.PeekMessages($count))
    }
    
    end {
        
    }
}