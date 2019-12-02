$key = "DefaultEndpointsProtocol=https;AccountName=devfakeprofilessa;AccountKey=wIOyeIJlo6hbnu//oQjYF6r5KId4qUArpOhcTkILfEMy+QZw1lXJ1eHxOraSXRNsFVUrWNS/gxhFZQz6c7y77A==;EndpointSuffix=core.windows.net"
ipmo "$PSScriptRoot\AzFnModule" -Force

$Ticks = [datetime]::Now.Ticks
# $Queue = Get-FnQueryFast -Connectionstring $ConnectionString -Name "singleton-$Name" -CreateIfNotExist

$_RunID = $Script:RunID
$Ticks = [datetime]::Now.Ticks
$RandomNumber = Get-random -Maximum 999999 -Minimum 0
$ID = "$_RunID-$Ticks-$RandomNumber"

Set-FnSingletonFlag -Name "test" -ConnectionString $key -Enable -TimeoutSec 10 -Verbose

$Q = Get-FnQueryFast -Connectionstring $key -Name "singleton-test" -CreateIfNotExist
New-FnQueryMessage -Queue $Q -Data "Test-$ID" -MessageLongevity ([timespan]::FromSeconds(10)) 
Set-FnSingletonFlag -Name "test" -ConnectionString $key -Enable -TimeoutSec 10 -Verbose
$Q|Clear-FnQueue


Set-FnSingletonFlag -Name "test" -ConnectionString $key -Enable -TimeoutSec 10 -Verbose