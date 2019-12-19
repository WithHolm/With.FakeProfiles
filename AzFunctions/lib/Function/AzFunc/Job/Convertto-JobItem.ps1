function Convertto-JobItem {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(ValueFromPipeline)]
        [pscustomobject]$Entity
    )
    
    begin {
        
    }
    
    process {
        $ret = [FakeProfile.Job]::new()
        $ret.Name = $entity.PartitionKey
        $ret.RowKey = [guid]::Parse($Entity.RowKey)
        $ret.Parent = [guid]::Parse($Entity.Parent)
        $ret.Children = $Entity.Children
        $ret.Comment = $entity.Comment
        $ret.Completed = $Entity.completed
        $ret.tag = $Entity.tag
        $ret.value = $entity.value
        $ret.Source = $Entity.Source
        Write-Output $ret
    }
    
    end {
        
    }
}