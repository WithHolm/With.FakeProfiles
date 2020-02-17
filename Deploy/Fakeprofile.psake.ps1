param(
    $ProjectRoot = (split-path $PSScriptRoot),
    [switch]$Force
)

Properties{
    $TempFuncFolder = "$ProjectRoot\AzFunctionsZip"
    $AzFuncFolder = join-path $ProjectRoot "AzFunctions"
    $InformationPreference = "Continue"
}

task default -depends deployresources,deploycode

task deployresources {
    $script:tfValues = @{}
    $OldLoc = Get-Location
    cd $PSScriptRoot
    terraform init
    terraform plan -out=tfplan -input=false
    if($Force)
    {
        terraform apply -input=false tfplan
    }
    else {
        terraform apply tfplan
    }
    
    $script:tfValues = terraform output -json|ConvertFrom-Json
    # |%{
    #     $split = $_.split("=")|%{$_.trim()}
    #     $script:tfValues.$($split[0]) = $split[1]
    # }
    cd $OldLoc
}

task compilecode{
    ipmo "$AzFuncFolder/lib/Modules/AzFnHelp" -force
    Build-FnEndpoints -WorkingDirectory  
    
}

task deploycode -depends deployresources -action {
    Write-Information "Zipping AzFunctions Content"
    $TempFolder = New-Item $TempFuncFolder -Force -ItemType Directory
    $TestFile = "$TempFuncFolder\AzFunc.zip"
    Write-Information "Compressing $testfile"
    Compress-Archive -Path (Get-ChildItem $AzFuncFolder).FullName -DestinationPath $TestFile -Force
    # get-item "C:\Users\Phil\source\repos\With.FakeProfiles\AzFunctions\Singleton"|
    # Write-Information "Getting Publishing cred"
    # $param = @{
    #     ResourceGroupName = $script:tfValues.ResourceGroupName
    #     ResourceType = "Microsoft.Web/sites/config"
    #     ResourceName = "$($script:tfValues.FunctionAppName)/publishingcredentials"
    #     Action = "list"
    #     ApiVersion = "2019-08-01"
    #     Force = $true
    # }
    # $creds = Invoke-AzResourceAction @param
    $username = $script:tfValues.publish_username.value
    $password = $script:tfValues.publish_password.value

    # Write-Information $username
    # Write-Information $password

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

    $apiUrl = "https://$($script:tfValues.FunctionAppName.value).scm.azurewebsites.net/api/zipdeploy"
    # $filePath = "<yourFunctionName>.zip"
    Write-Information "Uploading to '$apiUrl'"
    Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method Post -InFile $TestFile -ContentType "multipart/form-data"
    Write-Information "Go to https://$($script:tfValues.FunctionAppName.value).scm.azurewebsites.net -> Debug menu at the top -> CMD -> Site -> wwwroot to check the contents"
} -postaction {
    Write-Information "Removing $TempFuncFolder"
    get-item $TempFuncFolder|Remove-Item -Force -Recurse
}