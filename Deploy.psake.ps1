param(
    [ValidateSet("Deploy","Teardown")]
    [string]$Action = "Deploy",

    [ValidateSet("Prod","Dev")]
    [string]$Pipeline
)

#Region Cmdlets
function Format-StringModern {
    [CmdletBinding()]
    param (
        [string]$InputString,
        $object
    )
    
    begin {
        
    }
    
    process {
        # Write-Verbose "Input = $InputString"
        [regex]::Matches($InputString,"([{].*?[}])")|ForEach-Object{
            $Key = $_.value.substring(1,$_.length-2)
            # Write-verbose "Key is $key"
            if($key.StartsWith("CMD:",[System.StringComparison]::InvariantCultureIgnoreCase))
            {
                $value = invoke-expression -Command $key.substring(4)
            }
            else {
                $value = $object
                $key.split(".")|ForEach-Object{
                    $value = $value.$_
                }
            }
            $Inputstring = $Inputstring.Replace($_,($value).tostring()) 
        }
        return $InputString
    }
    
    end {
        
    }
}

Function FlattenObject {
    [CmdletBinding()]
    param(
        $Object,
        $address
    )
    if($Object -is [hashtable])
    {
        $Object.keys|%{
            $key = $_
            $thisaddress = ($(@($address,$key)|?{![string]::IsNullOrEmpty($_)}) -join ".")
            Write-Verbose $thisaddress
            if($Object.$_ -is [hashtable] -or $object.$_ -is [array])
            {
                Write-Verbose "calling flatten on object '$thisaddress'"
                FlattenObject -Object $Object.$_ -address $thisaddress
            }
            else {
                Write-output @{$thisaddress = $object[$key]}
            }
        } 
    }
    elseif($Object -is [array]) {
        for ($i = 0; $i -lt $Object.Count; $i++) {
            $thisaddress = ($(@($address,"$i")|?{![string]::IsNullOrEmpty($_)}) -join ".")
            Write-Verbose $thisaddress
            if($Object[$i] -is [hashtable] -or $object[$_] -is [array])
            {
                Write-Verbose "calling flatten on object '$key'"
                FlattenObject -Object $Object.$_ -address $thisaddress
            }
            else {
                Write-output @{$thisaddress = $object[$i]}
            }
        }
    }
}



function Get-TenantID
{
    <#
        .Synopsis
        Get The TenantID of a specified domain name or UPN/Mail
        .EXAMPLE
        Get-Tenant "Domain.com"
        .EXAMPLE
        get-Tenant "User@Domain.com"
        .OUTPUTS
        String
    #>
    [CmdletBinding(DefaultParameterSetName = "Dynamic")]
    param (
        [Parameter(
            ParameterSetName = 'Dynamic',
            Position = 0)]
        [object]$input,
        [Parameter(ParameterSetName = 'Domain')]
        [String]$Domain,
        [Parameter(ParameterSetName = 'Upn')]
        [String]$UPN
    )
    
    process
    {
        if ($PSBoundParameters.ContainsKey("input"))
        {
            $input = $($PSBoundParameters["input"])
            write-verbose "Object $($input)"
            if ($input -like "*@*")
            {
                return $(Get-TenantID -UPN $input)
            }
            else
            {
                return $(Get-TenantID -Domain $input) 
            }
        }
        elseif ($PSBoundParameters.ContainsKey("UPN"))
        {
            $Domain = $upn.split('@')[-1]
        }

        $OpenIDConfig = Invoke-RestMethod -Method get -UseBasicParsing -Uri "https://login.windows.net/$domain/.well-known/openid-configuration"
        $return = $OpenIDConfig.authorization_endpoint.Split("/").where{try {[guid]::Parse($_) -ne $null}catch {$false}}|select -first 1

        if (!$return)
        {
            throw "Could not find TenantID for $domain"
        }
        else
        {
            return $return
        }
    }
}

$InformationPreference = "Continue"
#Endregion

Properties{
    $Options = Import-PowerShellDataFile -Path "$PSScriptRoot\Options.psd1"
    if(!$Pipeline)
    {
        $Pipeline = $options.Project.Pipeline 
    }
    $Location = $options.az.location
    $DeploymentName = "$Pipeline-$($options.projectname)"
    $ResourceTag = @{
        Pipeline=$Pipeline
        Project=$options.project.name
    }
    $FormatStringRefObject = @{
        Action = $Action
        Pipeline=$Pipeline
        Options=$options
    }

}



task default -depends Validate,Teardown,Deploy

task Deploy -precondition {$Action -eq "Deploy"} -depends DeployResources,SetupSolutionConfig,DeployCode {
    foreach($res in $options.az.resources.getenumerator()|?{$_.name -ne "ResourceGroup"})
    {
        Write-Output "Checking that $($res.name) is deployed"
        $ResourceName = Format-StringModern -InputString $res.value.name  -object $FormatStringRefObject
        # Write-Output "Name = $ResourceName"
        $resource = Get-AzResource -ResourceGroupName $script:ResourceGroupName -Name $ResourceName
        if(!$resource)
        {
            Write-Warning "Could not find resource $($res.name):'$ResourceName'"
            throw 
        }
    }
    resource ""
}

task Teardown -precondition {$Action -eq "Teardown"} {
    $Script:ResourceGroupName = Format-StringModern -InputString $options.az.resources.ResourceGroup.name  -object $FormatStringRefObject
    $ResourceGroup = Get-AzResourceGroup|Where-Object{$_.ResourceGroupName -eq $Script:ResourceGroupName}
    if($ResourceGroup)
    {
        Write-Output "Removing Resourcegroup $Script:ResourceGroupName"
        $ResourceGroup|Remove-AzResourceGroup -Force -Verbose
    }

    #AzAdAccount
    $AppName = Format-StringModern -InputString $options.az.resources.AutomationAccount.RunAsAccountName  -object $FormatStringRefObject
    $AdApp = Get-AzADApplication -DisplayName $AppName
    if($AdApp)
    {
        Write-Output "Removing AD app $appname"
        $AdApp|Remove-AzADApplication -Force
    }
}

task DeployResources -depends ResourceGroup,StorageAccount,AppServicePlan,FunctionsApp,CognitiveServices_Face

# Task AutomationServices -depends AutomationAccount,ADRunAsAccount,AutomationConnection

Task Validate{
    $Context = Get-AzContext
    $TenantID = Get-TenantID -Domain $options.az.tenantname

    if($Context.Tenant.Id -ne $TenantID)
    {
        Throw "Context is not set to correct tenant. Should be '$TenantID'($($options.az.tenantname)), but is $($Context.Tenant.Id)"
    }
    else {
        Write-Information "Connected to the correct tenant '$($options.az.tenantname)'"
    }

    if($Context.Subscription.Name -ne $options.az.SubscriptionName)
    {
        Throw "Context is not set to correct tenant. Should be '$($options.az.SubscriptionName)', but is $($Context.Subscription.Name)"
    }
    else {
        Write-Information "Connected to the correct subscription '$($options.az.SubscriptionName)'"
    }

}

Task ResourceGroup{
    # $DebugPreference = "Continue"
    $Script:ResourceGroupName = Format-StringModern -InputString $options.az.resources.ResourceGroup.name  -object $FormatStringRefObject
    $ResourceGroup = Get-AzResourceGroup|?{$_.ResourceGroupName -eq $Script:ResourceGroupName}
    if(!$ResourceGroup)
    {
        Write-Output "Creating new ResourceGroup:'$ResourceGroupName'"
        $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Tag $ResourceTag -Location $options.Az.Location
    }
    else {
        Write-Output "ResourceGroup '$ResourceGroupName' already exists"
    }
    $script:ResourceGroup = $ResourceGroup
    # else {
    #     Write-Output "Updating Resourcegroup tags: $($ResourceTag)"
    #     $ResourceGroup|Set-AzResourceGroup -Tag $ResourceTag
    # }
}

Task StorageAccount -depends ResourceGroup{
    $Script:StorageAccountName = Format-StringModern -InputString $options.az.resources.StorageAccount.name -object $FormatStringRefObject
    $Script:StorageAccountName = $Script:StorageAccountName.tolower()
    $Script:StorageAccount = Get-AzStorageAccount|?{$_.StorageAccountName -like "$StorageAccountName*" -and $_.ResourceGroupName -like "$DeploymentName*"}
    if(!$StorageAccount)
    {
        Write-Output "Creating new StorageAccount:'$script:StorageAccountName'"
        $Script:StorageAccount = New-AzStorageAccount -Location $options.az.location -Name $StorageAccountName -Tag $ResourceTag -SkuName $options.az.resources.storageaccount.sku -Kind StorageV2 -ResourceGroupName $Script:ResourceGroupName
    }
    else {
        Write-Output "StorageAccountName $StorageAccountName already exists"
    }

    Write-Information "Testing that all storage tables have been made"
    $tables = $Script:StorageAccount|Get-AzStorageTable 
    if(@($options.az.resources.StorageAccount.Tables).count -gt 0)
    {
        foreach($strtable in $options.az.resources.StorageAccount.Tables)
        {
            if(!($tables|?{$_.Name -eq $strtable}))
            {
                Write-Information "`tCreating Table '$strtable'"
                New-AzStorageTable -Name $strtable -Context $StorageAccount.Context
            }
            else {
                Write-Information "`tTable '$strtable' already created"
            }
        }
    }

    Write-Information "Testing that all storage containers have been made"
    $containers = $Script:StorageAccount|Get-AzStorageContainer
    if(@($options.az.resources.StorageAccount.Containers).count -gt 0)
    {
        foreach($Container in $options.az.resources.StorageAccount.Containers)
        {
            if(!($containers|?{$_.Name -eq $Container}))
            {
                Write-Information "`tCreating container '$Container'"
                New-AzStorageContainer -Name $Container -Context $Script:StorageAccount.Context
            }
            else {
                Write-Information "`tcontainer '$Container' alredy created"
            }
        }
    }

    Write-Information "Testing that all storage queue have been made"
    $Queues = $Script:StorageAccount|Get-AzStorageQueue
    if(@($options.az.resources.StorageAccount.Queues).count -gt 0)
    {
        foreach($Qu in $options.az.resources.StorageAccount.Queues)
        {
            if(!($Queues|?{$_.Name -eq $Qu}))
            {
                Write-Information "`tCreating container '$Qu'"
                New-AzStorageQueue -Name $Qu -Context $Script:StorageAccount.Context
            }
            else {
                Write-Information "`tcontainer '$Qu' alredy created"
            }
        }
    }

    
    # $script:StorageAccount = $StorageAccount
}

Task AppServicePlan -depends ResourceGroup{
    $script:AppServicePlanName = Format-StringModern -InputString $options.az.resources.AppservicePlan.name -object $FormatStringRefObject
    # $script:AppServicePlanName = "($script:AppServicePlanName.tolower())-Farm"
    $AppServicePlan = Get-AzAppServicePlan -Name $script:AppServicePlanName -ResourceGroupName $Script:ResourceGroupName # -ResourceType "Microsoft.Web/serverfarms" -Name $script:AppServicePlanName
    if(!$AppServicePlan)
    {
        Write-output "Creating new AppServicePlan:'$script:AppServicePlanName'"
        $AppServicePlan = New-AzAppServicePlan -Location $options.az.location -ResourceGroupName $Script:ResourceGroupName -Name $script:AppServicePlanName -Tier Free  # -Tag $ResourceTag #-WorkerSize Small -NumberofWorkers 1
    }
    else {
        Write-Output "AppservicePlan '$script:AppServicePlanName' already exists"
    }

    $script:AppServicePlan = $AppServicePlan
    # $AppServicePlan
}

Task FunctionsApp -depends ResourceGroup,AppServicePlan,CognitiveServices_Face{
    $Script:FunctionsName = Format-StringModern -InputString $options.az.resources.functions.name  -object $FormatStringRefObject
    $Script:FunctionsName = $Script:FunctionsName.tolower()

    $ProgressPreference = "Silentlycontinue"
    $FunctionsApp = Get-AzWebApp |Where-Object{
        $_.name -eq $Script:FunctionsName -and 
        $_.Kind -like "func*" -and 
        $_.ResourceGroup -eq $Script:ResourceGroupName
    }
    $ProgressPreference = "Continue"
    # $FunctionsApp
    if(!$FunctionsApp)
    {
        Write-Output "Creating new FunctionsApp:'$Script:FunctionsName'"
        # Write-Output "Getting Key from Storageaccount '$script:StorageAccountName'"
        $FunctionsApp = New-AzResource `
        -ResourceGroupName $Script:ResourceGroupName `
        -ResourceType "Microsoft.Web/sites" `
        -Kind "functionapp" `
        -Location $options.az.Location `
        -ResourceName $Script:FunctionsName `
        -Tag $ResourceTag `
        -Properties @{
            # name = $Script:FunctionsName
            clientAffinityEnabled = $true
            serverFarmId = (Get-AzAppServicePlan -Name $Script:AppServicePlanName -ResourceGroupName $Script:ResourceGroupName).Id
            AlwaysOn = $false
        } `
        -Force 
    }
    Else{
        Write-Output "FunctionsApp '$Script:FunctionsName' already exists"
    }

    Write-Output "Setting extra settings for $script:FunctionsName"
    $appsettings = @{
        FUNCTIONS_WORKER_RUNTIME = "Powershell"
        FUNCTIONS_EXTENSION_VERSION = "~2"
        AzureWebJobsStorage = "DefaultEndpointsProtocol=https;AccountName=$($script:StorageAccountName);AccountKey=$(($script:StorageAccount|Get-AzStorageAccountKey)[0].value);EndpointSuffix=core.windows.net"
        API_Location_Face = $location.replace(" ",'')
        API_SubscriptionKey_Face = ($Script:Cogninitiveservices|Get-AzCognitiveServicesAccountKey).key1
        PSWorkerInProcConcurrencyUpperBound = "$($options.Az.Resources.Functions.Concurrencycount)"
    }
    
    @{
        IsEncrypted = $false
        Values = [pscustomobject]$appsettings
    }|ConvertTo-Json|out-file $(Join-Path (Join-Path $PSScriptRoot $options.az.resources.functions.LocalPath) "local.settings.json")

    $FunctionsApp = Set-AzWebApp -Name $script:FunctionsName -ResourceGroupName $Script:ResourceGroupName -AppSettings $appsettings -AssignIdentity $true 

    $script:FunctionsApp = $FunctionsApp
}

Task SetupSolutionConfig{
    $AddArray = @()
    foreach($Key in $options.project.Azconfig.keys)
    {
        # $Key
        $Main = $options.project.Azconfig.$key
        foreach($subkey in $Main.keys)
        {
            $Sub = $Main.$subkey
            $AddArray += @{
                PartitionKey = $key
                RowKey = $subkey
                property = @{
                    Value = $Sub|ConvertTo-Json -Depth 99
                }
            }
        }
    }
    
    $Tbl = Get-AzTableTable -TableName $options.project.ConfigName -storageAccountName $Script:StorageAccount.StorageaccountName -resourceGroup $Script:StorageAccount.ResourcegroupName
    
    Write-Information "Removing old Config"
    Get-AzTableRow -Table $Tbl|%{
        [void](Remove-AzTableRow -Table $Tbl -RowKey $_.RowKey -PartitionKey $_.PartitionKey)
    }

    $AddArray|%{
        $HT = $_
        Write-Information "Adding config $($_|ConvertTo-Json -Compress)"
        [void](Add-AzTableRow -Table $Tbl @HT)
    }
}

Task KeyVault -depends ResourceGroup{
    $script:KeyvaultName = Format-StringModern -InputString $options.az.resources.KeyVault.name  -object $FormatStringRefObject
    $Keyvault = Get-AzKeyVault|Where-Object{$_.VaultName -eq $script:KeyvaultName -and $_.ResourceGroupName -eq $script:ResourceGroupName}
    if(!$Keyvault)
    {
        Write-Output "Creating new Keyvault:'$script:KeyvaultName'"
        $Keyvault = New-AzKeyVault -Name $script:KeyvaultName -ResourceGroupName $script:ResourceGroupName -Sku Standard -Location $options.az.location 
    }
    else {
        Write-Output "KeyVault '$script:KeyvaultName' already exists"
    }

    $Azcontext = Get-AzContext
    Write-Output "Setting Accesspolicy for $($Azcontext.Account.id)"
    $AADUser = get-azaduser|?{
        $UPN = $_.UserPrincipalName
        $false -notin ($Azcontext.Account.id.split('@')|%{
            write-verbose "$upn : $_ $(($upn -like "*$_*")) "
            $upn -like "*$_*"
        })
    }
    if(@($Aduser).count -ne 1)
    {
        throw "Should have found 1 account for the user $($Azcontext.Account.id), but found $(@($AADUser).count). Keyvault accesspolicy requires objectID"
    }
    $CertPermission = @('get','list','set','delete','backup','restore','recover','purge')
    $keyvault|Set-AzKeyVaultAccessPolicy -ObjectId $AADUser.Id -PermissionsToKeys create,list,get,list,delete -PermissionsToSecrets $CertPermission -PermissionsToCertificates create,get,list,delete
    $script:Keyvault = $Keyvault
}

Task CognitiveServices_Face -depends ResourceGroup{
    $Script:CogninitiveservicesName = Format-StringModern -InputString $options.az.resources.CognitiveServices_Face.name  -object $FormatStringRefObject
    $CognitiveServices = Get-AzCognitiveServicesAccount|?{$_.AccountName -eq $Script:CogninitiveservicesName -and $_.ResourceGroupName -eq $script:ResourceGroupName}
    if(!$CognitiveServices)
    {
        Write-Output "Creating Cognitive service '$Script:CogninitiveservicesName'"
        $CognitiveServices = New-AzCognitiveServicesAccount -Name $Script:CogninitiveservicesName -ResourceGroupName $script:ResourceGroupName -Type Face -SkuName F0 -Location $location
    }
    else {
        Write-Output "Cognitive service '$Script:CogninitiveservicesName' already exists"
    }
    $Script:Cogninitiveservices = $CognitiveServices
}

Task DeployCode -depends FunctionsApp{

    Write-Information "Zipping AzFunctions Content"
    $TempFolder = New-Item "$PSScriptRoot\AzFunctionsZip" -Force -ItemType Directory
    $TempFolder.FullName
    $TestFile = "$($TempFolder.fullname)\AzFunc.zip"
    Write-Information "Compressing $testfile"
    Compress-Archive -Path (Get-ChildItem "C:\Users\Phil\source\repos\With.FakeProfiles\AzFunctions\").FullName -DestinationPath $TestFile -Force
    # get-item "C:\Users\Phil\source\repos\With.FakeProfiles\AzFunctions\Singleton"|
    Write-Information "Getting Publishing cred"
    $param = @{
        ResourceGroupName = $script:ResourceGroupName
        ResourceType = "Microsoft.Web/sites/config"
        ResourceName = "$($script:FunctionsApp.Name)/publishingcredentials"
        Action = "list"
        ApiVersion = "2019-08-01"
        Force = $true
    }
    $creds = Invoke-AzResourceAction @param
    $username = $creds.Properties.PublishingUserName
    $password = $creds.Properties.PublishingPassword

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

    $apiUrl = "https://$($script:FunctionsName).scm.azurewebsites.net/api/zipdeploy"
    # $filePath = "<yourFunctionName>.zip"
    Write-Information "Uploading to '$apiUrl'"
    Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method Post -InFile $TestFile -ContentType "multipart/form-data"
    Write-Information "Go to https://$($script:FunctionsName).scm.azurewebsites.net -> Debug menu at the top -> CMD -> Site -> wwwroot to check the contents"
}