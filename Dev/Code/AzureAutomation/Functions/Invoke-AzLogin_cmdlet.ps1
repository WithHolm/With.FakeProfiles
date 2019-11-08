function Invoke-AzLogin {
    [CmdletBinding()]
    param (
        $AutomationAccountName,
        $SubscriptionName
    )
    
    begin {
    }
    
    process {
        if([bool]$env:AUTOMATION_ASSET_KEY)
        {
            $connectionName = "AzureRunAsConnection"
            try
            {
                # Get the connection "AzureRunAsConnection "
                $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
            
                "Logging in to Azure..."
                $Loginparam = @{
                    ServicePrincipal = $true
                    TenantId = $servicePrincipalConnection.TenantId
                    ApplicationId = $servicePrincipalConnection.ApplicationId
                    CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
                }
                Add-AzAccount @Loginparam
                
            }
            catch {
                if (!$servicePrincipalConnection)
                {
                    $ErrorMessage = "Connection $connectionName not found."
                    throw $ErrorMessage
                } else{
                    Write-Error -Message $_.Exception
                    throw $_.Exception
                }
            }
        }
        else {
            if($SubscriptionName -notin @((Get-AzSubscription).Name))
            {
                Login-AzAccount
            }
        }
        Set-AzContext -SubscriptionObject (Get-AzSubscription -SubscriptionName $SubscriptionName)
    }
    
    end {
    }
}