Properties{
    $DeployFile = "$PSScriptRoot\Deploy.json"
    $ParameterFile = "$PSScriptRoot\Parameter.json"
}
task default -depends Deploy

task GenerateAzAutomationModuleList{
    $DeployObject = get-content $DeployFile -Raw|ConvertFrom-Json
    foreach($item in ((find-module az).Dependencies.name))
    {
        $it = [pscustomobject]@{
            type = "Microsoft.Automation/automationAccounts/modules"
            apiVersion = "2015-10-31"
            name = "[concat(parameters('automationAccounts_testtttt_name'), '/$item')]"
            dependsOn = @(
                "[resourceId('Microsoft.Automation/automationAccounts', parameters('automationAccounts_testtttt_name'))]"
            )
            "properties"=[pscustomobject]@{
                contentLink = @{}
            }
        }
        ($DeployObject.resources|?{$_.type -like "*deployments"}).properties.template.resources += $it
    }

}

task Deploy -action {

    # $ParameterObject = get-content $ParameterFile -Raw|ConvertFrom-Json
    # $DeployObject = get-content $DeployFile -Raw|convertfrom-json
    New-AzDeployment -TemplateParameterFile $ParameterFile -TemplateFile $DeployFile -Location westeurope -Name test -Verbose
}

# Task GenerateParameters -action {
#     Foreach($DeployTemplate in $(Get-childitem $Templatepath -Recurse -Filter "deploy.json"))
#     {
#         Write-Output $DeployTemplate.fullname
#         $Deploy = Get-content -Path $DeployTemplate.fullname -Raw|ConvertFrom-Json
#         $ParameterPath = (join-path  $DeployTemplate.directory "Parameters.json")
#         if(Test-path $ParameterPath)
#         {
#             $parameters = Get-content -Path $DeployTemplate.fullname -Raw|ConvertFrom-Json
#         }
#         $parameters = 
#         foreach()
#         Write-Output $Deploy.Parameters
#         # $Depolyparameters = 
#     }
# }

# Task BuildTemplates -action {

# }