Properties{
    $DeployPath = "$PSScriptRoot\Deploy"
}
Task default -depends Build,Deploy

Task Login {
    # $Context = Get-AzContext -ErrorAction SilentlyContinue
    # $DefinedID = (Get-content $PSScriptRoot\Options.json -Raw|ConvertFrom-Json).AzureContext.LoginId
    # $LoginRequired = $true
    # if(![string]::IsNullOrEmpty($DefinedID))
    # {
    #     if($Context)
    #     {
    #         if($Context.Account.Id -eq $)
    #     }
    # }
    # else {
    #     Write-Warning "You can define your "
    # }
}

Task Deploy -depends Login -action {
        if(test-path (join-path $DeployPath "Azure_Deployment.json"))
        {
            
        }
        If([String]::IsNullOrEmpty())
}

Task Build{

}