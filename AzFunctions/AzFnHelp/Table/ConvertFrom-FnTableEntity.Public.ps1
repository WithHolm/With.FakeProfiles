using namespace Microsoft.Azure.Storage
function Convertfrom-FnTableEntity{
    [CmdletBinding()]
    [outputtype([pscustomobject],[Hashtable])]
    param (
        [parameter(ValueFromPipeline)]
        [pscustomobject]$TableEntity,
        [switch]$AsHashTable
    )
    
    begin {
    }
    
    process {
        $Output = @{}
        #
        $TableEntity.PSObject.properties | 
            Where-Object{$_.name -notin "PartitionKey","RowKey","TableTimestamp","Etag"}|
                Foreach-Object {
                    $Value = $_.value
                    if(![string]::IsNullOrEmpty($Value))
                    {
                        $value = $value
                    }
                    $Output[$_.Name] = $value
        }
        
        if(!$AsHashTable)
        {
            $Output = [pscustomobject]$Output
        }
        Write-Output $Output
    }
    
    end {
        
    }
}