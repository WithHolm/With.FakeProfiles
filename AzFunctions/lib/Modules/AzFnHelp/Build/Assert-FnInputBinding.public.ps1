function Assert-FnBinding {
    [CmdletBinding()]
    param (
        $Name,

        [parameter(Mandatory,ParameterSetName="Out")]
        [switch]$Out,
        [parameter(Mandatory,ParameterSetName="In")]
        [switch]$In,
        
        [parameter(Mandatory,ParameterSetName="In")]
        [parameter(Mandatory,ParameterSetName="Queue")]
        [switch]$Queue,
        [parameter(Mandatory,ParameterSetName="In")]
        [parameter(Mandatory,ParameterSetName="Out")]
        [parameter(Mandatory,ParameterSetName="Http")]
        [switch]$Http,
        [parameter(Mandatory,ParameterSetName="In")]
        [parameter(Mandatory,ParameterSetName="Timer")]
        [switch]$Timer,
        
        [parameter(Mandatory,ParameterSetName="In")]
        [parameter(Mandatory,ParameterSetName="Http")]
        [ValidateSet("Get","Post","Put")]
        [Microsoft.PowerShell.Commands.WebRequestMethod[]]$HttpMethods = "Get",
        
        [parameter(ParameterSetName="In")] 
        [parameter(ParameterSetName="Http")]
        [ValidateSet("function","anonymous","admin")]
        [String]$HttpAuthLevel="admin",
        
        [parameter(Mandatory,ParameterSetName="In")] 
        [parameter(Mandatory,ParameterSetName="Http")]
        [ValidateSet("function","anonymous","admin")]
        [String]$Route="admin",

        [parameter(ParameterSetName="In")] 
        [parameter(ParameterSetName="Out")]
        [parameter(ParameterSetName="Http")]
        [ValidateSet("Binary","Stream","String")]
        [string]$Datattype,
        
        [parameter(Mandatory,ParameterSetName="In")]
        [parameter(Mandatory,ParameterSetName="Queue")]
        [String]$QueueName,
        
        [parameter(Mandatory,ParameterSetName="In")]
        [parameter(Mandatory,ParameterSetName="Queue")]
        [String]$ConnectionStringEnvName,
        
        [parameter(Mandatory,ParameterSetName="In")]
        [parameter(Mandatory,ParameterSetName="Timer",HelpMessage="CRON expression")]
        [String]$ScheduleString

    )
    
    begin {
        if([string]::IsNullOrEmpty($Global:Build_Function))
        {
            return $null
        }
        
        if(!$BindingName)
        {
            if($Queue)
            {
                $BindingName = 'QueueItem'
            }
            elseif($Http)
            {
                $BindingName = 'Request'
            }
            elseif($Timer)
            {
                $BindingName = 'Timer'
            }
            Write-Verbose "Setting default bindingname:'$BindingName'"
        }
        if($Queue)
        {
            $Type = 'queueTrigger'
        }elseif($Http)
        {
            $Type = 'httpTrigger'
        }elseif($Timer)
        {
            $Type = 'httpTrigger'
        }
        Write-verbose "Setting triggertype '$type'"
    }
    
    process {
        $Binding = [ordered]@{
            direction = 'in'
            name = $BindingName
            type = $Type
        }
        if($Http)
        {
            $binding.authLevel = $AuthLevel
            $Binding.Methods = @($HttpMethods)
        }
        if($Queue)
        {
            $Binding.queueName = $QueueName
            $Binding.connection = $ConnectionStringEnvName
        }
        if($Timer)
        {
            $Binding.schedule = $ScheduleString
        }
        $Binding
    }
    
    end {
        
    }
}