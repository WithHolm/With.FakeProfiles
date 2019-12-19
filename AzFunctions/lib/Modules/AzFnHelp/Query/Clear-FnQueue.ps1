function Clear-FnQueue {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(ValueFromPipeline)]
        [Microsoft.Azure.Storage.Queue.CloudQueue]$Queue,
        [switch]$Async
    )
    
    begin {
        
    }
    
    process {
        if ($pscmdlet.ShouldProcess($Queue.Name, "Clear")) {
            if($Async)
            {
                [void]$Queue.ClearAsync()
            }
            else {
                $Queue.Clear()
            }
        }
    }
    
    end {
        
    }
}