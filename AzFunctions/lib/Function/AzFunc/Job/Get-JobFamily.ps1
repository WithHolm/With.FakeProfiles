function Get-JobChildren {
    [CmdletBinding()]
    param (
        [Microsoft.Azure.Cosmos.Table.CloudTable]$Table,
        [FakeProfile.Job]$Job,
        [ValidateSet("Parent","Child")]
        [string]$Membertype
    )
    
    begin {
        
    }
    
    process {
        if($Membertype -eq "Child" -and $job.HasChildren())
        {
            Get-AzTableRow -Table $Table -CustomFilter "Parent eq '$($job.RowKey.ToString())'"|Convertto-JobItem
        }
        elseif ($Membertype -eq "Parent" -and $job.HasParent()) {
            Get-AzTableRow -Table $Table -CustomFilter "RowKey eq '$($job.Parent.ToString())'"|Convertto-JobItem
        }
    }
    
    end {
        
    }
}