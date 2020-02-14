function Assert-FnHttpBinding {
    [CmdletBinding()]
    param (
        [string]$Name,

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
        [string]$Datattype,
        
        [parameter(ParameterSetName="In")] 
        [switch]$SkipConstraintCheck
    )
    
    begin {
        if(!$name -and $in)
        {
            $Name = "Request"
        }
        elseif(!$name -and $out)
        {
            $Name = "Response"
        }
    }
    
    process {
        $binding = [ordered]@{
            name = $Name
            direction = $PSCmdlet.ParameterSetName.ToLower()          
            Methods = @()
        }
        if($in)
        {
            $binding.type = "httpTrigger"
            $binding.authLevel = $AuthLevel
        }
        else {
            $binding.type = "http"
        }

        if($Datattype)
        {
            $binding.dataType = $Datattype
        }

        if($Route)
        {
            if(!$SkipConstraintCheck)
            {
                Invoke-Tooltips -scope 'HttpBinding' -Variables @{Route=$Route}
                
                #https://docs.microsoft.com/en-us/aspnet/web-api/overview/web-api-routing-and-actions/attribute-routing-in-web-api-2#route-constraints
                #https://regex101.com/ -> 
                #   Regex: ((?'Dynamic'({)(?'variable'\w+)(?'param'(([:][a-zA-Z()0-9]+))*)(})))
                #   Test: products/{category:alpha}/{id:int}/{test}/{id:int:min(1)}
                # (([:][a-zA-Z()0-9]+))*
                # ((?'Dynamic'({)(\w*)(:[a-zA-Z()0-9?])*(})))
                <#
(\w*)(?'test':[a-zA-Z()0-9?]+)
category:alpha
id:int
test
id:int:min(1)
                #>
                #products/{category:alpha}/{id:int}/{test:regex((([:][a-zA-Z()0-9]+)))}/{id:int:min(1)}
                # [regex]::Matches($Route,"({(?'Dynamic'(?'var'\w*)(?'constraint'|:[a-zA-Z()0-9?]+)*)})")|%{
                #     Write-host "constraint '$($_.groups|?{$_.name -eq 'var'})' value: '$($_.groups|?{$_.name -eq 'dynamic'})'"
                #     # if()
                #     # [regex]::Matches(($_.groups|?{$_.name -eq 'dynamic'}),"(?'var'\w*)(?'constraint'|:[a-zA-Z()0-9?]+)")
                #     $_.Groups.captures.value #|?{$_.value -and $_.name -ne 'dynamic'}
                #     # $_.groups|?{$_.value -like ":*"}
                # }
            }
            $binding.route = $Route
        }

        if($Methods)
        {
            $binding.methods = $Methods|%{$_.ToLower()}
        }
        return $binding
    }
    
    end {
        
    }
}

# ({(?'name'\w*):\w*})
# ((?'variable'{\w+):(?'type'\w+})|{(?'string'\w+)})


# ((?'Dynamic'({)(?'variable'\w+)(?'param'([:][a-zA-Z()0-9]+))*(})))