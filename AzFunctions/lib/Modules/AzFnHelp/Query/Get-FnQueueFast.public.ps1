using namespace Microsoft.Azure.Storage
function Get-FnQueueFast {
    [CmdletBinding()]
    [outputtype([Microsoft.Azure.Storage.Queue.CloudQueue])]
    param (
        [parameter(Mandatory)]
        [String]$Connectionstring,
        [parameter(Mandatory)]
        [String]$Name,
        [Switch]$CreateIfNotExist
    )
    
    begin {
        #Do some checkgin that it correct.. 
        $Name = $Name.ToLower()
    }
    
    process {
        $CS = [Microsoft.Azure.Storage.cloudstorageaccount]::Parse($Connectionstring)
        $QueueClient = [Queue.CloudQueueClient]::new($cs.QueueStorageUri,$CS.Credentials)
        $Queue = $QueueClient.GetQueueReference($Name)
        if($CreateIfNotExist -and !$Queue.Exists())
        {
            Write-Verbose "Creating Queue '$Name'"
            [void] $Queue.CreateIfNotExists()
        }
        return $Queue
    }
    
    end {
        
    }
}