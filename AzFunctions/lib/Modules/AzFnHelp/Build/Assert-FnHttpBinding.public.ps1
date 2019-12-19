function Assert-FnHttpBinding {
    [CmdletBinding()]
    param (
        [string]$Name = 'Request',

        [parameter(Mandatory,ParameterSetName="Out")]
        [switch]$Out,
        [parameter(Mandatory,ParameterSetName="In")]
        [switch]$In,

        [parameter(ParameterSetName="In")]
        [ValidateSet('Get','Head','Post','Put','Delete','Trace','Options','Merge','Patch')]
        [string[]]$Methods,
        
        [parameter(ParameterSetName="In")] 
        [ValidateSet("function","anonymous","admin")]
        [String]$AuthLevel="admin",
        
        [parameter(ParameterSetName="In")] 
        [String]$Route,

        [parameter(ParameterSetName="In")] 
        [parameter(ParameterSetName="Out")]
        [ValidateSet("Binary","Stream","String")]
        [string]$Datattype
    )
    
    begin {
    }
    
    process {
        $binding = [ordered]@{
            name = $Name
            type = "Http"
            direction = $PSCmdlet.ParameterSetName
            authLevel = $AuthLevel
            Methods = @()
        }
        if($Datattype)
        {
            $binding.dataType = $Datattype
        }

        if($Route)
        {
            $binding.route = $Route
        }

        if($Methods)
        {
            $binding.methods = $Methods
        }
        return $binding
    }
    
    end {
        
    }
}