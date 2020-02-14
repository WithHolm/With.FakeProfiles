param(
    $ProjectRoot = (split-path $PSScriptRoot)
)

Properties{
    $AzFuncFolder = join-path $ProjectRoot "AzFunctions"
    $InformationPreference = "Continue"
}

task default -depends deployresources,deploycode

task deployresources {
    $global:tfValues = @{}
    $OldLoc = Get-Location
    cd $PSScriptRoot
    terraform plan -out=tfplan -input=false
    terraform apply -input=false tfplan -no-color
    
    terraform output|%{
        $split = $_.split("=")|%{$_.trim()}
        $global:tfValues.$($split[0]) = $split[1]
    }

    cd $OldLoc
}

task CreateStorageItems {
    
}

task deploycode -depends deployresources {
    Write-Information "Zipping AzFunctions Content"
    $TempFolder = New-Item "$ProjectRoot\AzFunctionsZip" -Force -ItemType Directory
    $TestFile = "$($TempFolder.fullname)\AzFunc.zip"
    Write-Information "Compressing $testfile"
    Compress-Archive -Path (Get-ChildItem $AzFuncFolder).FullName -DestinationPath $TestFile -Force
    # get-item "C:\Users\Phil\source\repos\With.FakeProfiles\AzFunctions\Singleton"|
    Write-Information "Getting Publishing cred"
    $param = @{
        ResourceGroupName = $Global:tfValues.ResourceGroupName
        ResourceType = "Microsoft.Web/sites/config"
        ResourceName = "$($Global:tfValues.FunctionAppName)/publishingcredentials"
        Action = "list"
        ApiVersion = "2019-08-01"
        Force = $true
    }
    $creds = Invoke-AzResourceAction @param
    $username = $creds.Properties.PublishingUserName
    $password = $creds.Properties.PublishingPassword

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

    $apiUrl = "https://$($Global:tfValues.FunctionAppName).scm.azurewebsites.net/api/zipdeploy"
    # $filePath = "<yourFunctionName>.zip"
    Write-Information "Uploading to '$apiUrl'"
    Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method Post -InFile $TestFile -ContentType "multipart/form-data"
    Write-Information "Go to https://$($Global:tfValues.FunctionAppName).scm.azurewebsites.net -> Debug menu at the top -> CMD -> Site -> wwwroot to check the contents"
}