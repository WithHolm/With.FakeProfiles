# get-command -Module pscognitiveservice
New-LocalConfiguration -  #  -Verbose | Out-Null
$path = "$PSScriptRoot\test.jpeg"
Get-Face -Path $path|ConvertTo-Json
# Get-ImageAnalysis -Path $path
# ConvertTo-Thumbnail -Path $path -OutFile "$PSScriptRoot\$([guid]::NewGuid().guid).jpeg" 