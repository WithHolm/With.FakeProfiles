# Input bindings are passed in via param block.
using namespace Microsoft.Azure.Storage
# using Microsoft.Azure.Storage
param(
    [byte[]] $InputBlob, 
    $TriggerMetadata
)
import-module "az.storage"
$TableName = "Faces"
# $StorageAccount = 
$Tempdir = [System.IO.DirectoryInfo]"$($env:TEMP)\img\$($TriggerMetadata.InvocationId)"
new-item -Path $Tempdir -ItemType Directory -Force|Out-Null
<#
[25-Oct-19 08:36:41] OUTPUT: Name                           Value
[25-Oct-19 08:36:41] OUTPUT: ----                           -----
[25-Oct-19 08:36:41] OUTPUT: FunctionName                   FreshImage
[25-Oct-19 08:36:41] OUTPUT: FunctionDirectory              C:\Users\Phil\source\repos\With.FakeProfiles\AzFunctions\FreshImage
[25-Oct-19 08:36:41] OUTPUT: Metadata                       {}
[25-Oct-19 08:36:41] OUTPUT: name                           fd86feef-2200-4c49-8241-0127a3283423
[25-Oct-19 08:36:41] OUTPUT: Properties                     {AppendBlobCommittedBlockCount, IsServerEncrypted, CacheControl, ContentDisposition.}
[25-Oct-19 08:36:41] OUTPUT: BlobTrigger                    pictures/Import/fd86feef-2200-4c49-8241-0127a3283423.jpeg
[25-Oct-19 08:36:41] OUTPUT: InvocationId                   1328da1c-ad70-41fa-bfdc-17fa3b67228e
[25-Oct-19 08:36:41] OUTPUT: Uri                            https://devfakeprofilessa.blob.core.windows.net/pictures/Import/fd86feef-2200-4c49-8241-.
[25-Oct-19 08:36:41] OUTPUT: sys                            {UtcNow, RandGuid, MethodName}
#>
Get-ChildItem $PSScriptRoot -Filter "*asset.ps1"|%{
    . $_.FullName
}
Write-Host "PowerShell Blob trigger function Processed blob! Name: $($TriggerMetadata.Name) Size: $($InputBlob.Length) bytes"

try{
    $ErrorActionPreference = "stop"
    $cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
    # [Microsoft.Azure.Storage.]
    Write-Debug "Connecting to storageaccount '$($CS.credentials.AccountName)'"
    $sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName} #-Name "" -ResourceGroupName 'Dev-FakeProfiles-RG'
    $Container = $sa|Get-AzStorageContainer|?{$_.name -eq $($TriggerMetadata.BlobTrigger.split('/')[0])}
    Write-Debug "Getting table '$TableName'"
    $table = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName $TableName

    Write-Debug "Getting table 'config'"
    $Config = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName "Config"
    $Dimensions = (Get-AzTableRow -PartitionKey "Resize" -RowKey "Dimension" -Table $Config).value|ConvertFrom-Json
    $EncoderQL = (Get-AzTableRow -PartitionKey "Image" -RowKey "Quality" -Table $Config).value|ConvertFrom-Json
    $StorageFolder = (Get-AzTableRow -PartitionKey "Image" -RowKey "Storage" -Table $Config).value|ConvertFrom-Json

    $Memorystream = [System.IO.MemoryStream]::new($InputBlob)
    $InputImage = [System.Drawing.Image]::FromStream($Memorystream)

    Write-Debug "Setting image dimentions: $($Dimensions -join ',')"
    foreach($size in $Dimensions)
    {
        $bitmap = Invoke-ResizeImage -Image $InputImage -Size $size
        $tempimage = ([System.Drawing.Image]$bitmap)
        $Filename = (Join-Path $Tempdir.FullName "$($tempimage.Height).jpeg")
        $JpegEndocer = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|?{$_.FormatDescription -eq "JPEG"}

        #Get reference to param 'quality'
        $QL = [System.Drawing.Imaging.Encoder]([System.Drawing.Imaging.Encoder]::Quality)
        #New Encodingparam
        $EncoderParam = [System.Drawing.Imaging.EncoderParameters]::new(1)
        #Add 'Quality' to encodingparam
        $EncoderParam.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new($QL,$EncoderQL)

        $bitmap.Save($Filename,$JpegEndocer,$EncoderParam)
        $tempimage.Dispose()
    }
    
    Write-Debug "Saving image Dimensions reference to table"
    $Entity = Get-AzTableRow -Table $table -PartitionKey $TriggerMetadata.Name -RowKey "Dimensions"
    if($Entity)
    {
        Write-debug "Updating existing entity"
        $entity.value = ($Dimensions|ConvertTo-Json -AsArray)
        [void](Update-AzTableRow -Table $table -entity $Entity)
    }
    else {
        Write-Information "creating new entity"

        #Add reference to uri
        $TableRowBaseParam = @{
            Table = $table
            PartitionKey = $TriggerMetadata.Name
        }
        $Property = @{
            Value = "$($container.CloudBlobContainer.uri.LocalPath)/$StorageFolder/$($TriggerMetadata.Name)"
        }
        [void](Add-AzTableRow @TableRowBaseParam -RowKey "ProfileBase" -property $property)      

        #Add Dimensions
        $property = @{
            Value = ($Dimensions|ConvertTo-Json -AsArray)
        }
        [void](Add-AzTableRow @TableRowBaseParam -Rowkey "Dimensions" -property $property)          
    }
    
    
    Write-Information "Uploading $($Dimentions.Count) files to blob"
    Get-ChildItem $Tempdir|%{
        [void]($Container|Set-AzStorageBlobContent -File $_.FullName -Blob $((@($StorageFolder,$TriggerMetadata.Name,$_.name)|Where-Object{$_}) -join "\") -Force)
    }
}
catch{
    throw $_
}
Finally{
}
Write-debug "Removing $($TriggerMetadata.BlobTrigger)"
$Container|Remove-AzStorageBlob -Blob ($($TriggerMetadata.BlobTrigger.split('/')|select -Skip 1) -join "/") -Force