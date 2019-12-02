$script:PowerShellWorkerPath = "$env:APPDATA\npm\node_modules\azure-functions-core-tools\bin\workers\powershell"  

Add-Type -Path "$script:PowerShellWorkerPath/Microsoft.Azure.Functions.PowerShellWorker.dll"
Import-Module "$script:PowerShellWorkerPath/Modules/Microsoft.Azure.Functions.PowerShellWorker" 

$addMethod = [psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators").GetMethod("Add", [type[]]@([string], [type]))
$addMethod.Invoke($null, @("HttpResponseContext", [Microsoft.Azure.Functions.PowerShellWorker.HttpResponseContext]))
$addMethod.Invoke($null, @("HttpRequestContext", [Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext]))