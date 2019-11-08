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
# Write out the blob name and size to the information log.
Write-Host "PowerShell Blob trigger function Processed blob! Name: $($TriggerMetadata.Name) Size: $($InputBlob.Length) bytes"
# $TriggerMetadata
#Get Storageaccount Name from string
# [Microsoft.Azure.Management.Storage.c]
# [microsoft.]
try{
    $ErrorActionPreference = "stop"
    $cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
    Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
    $sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName} #-Name "" -ResourceGroupName 'Dev-FakeProfiles-RG'
    $Container = $sa|Get-AzStorageContainer|?{$_.name -eq $($TriggerMetadata.BlobTrigger.split('/')[0])}
    Write-Information "Getting table '$TableName'"
    $table = Get-AzTableTable -resourceGroup $sa.ResourceGroupName -storageAccountName $sa.StorageAccountName -TableName $TableName

    # Write-Information "Setting Image Sizes"
    $Memorystream = [System.IO.MemoryStream]::new($InputBlob)
    $InputImage = [System.Drawing.Image]::FromStream($Memorystream)
    $Dimentions = @(90,256,512,$InputImage.Height)
    Write-Information "Setting image dimentions: $($Dimentions -join ',')"
    foreach($size in $Dimentions)
    {
        # Write-Information "Setting size $size"
        # $Dimentions += $size
        $bitmap = Invoke-ResizeImage -Image $InputImage -Size $size
        $tempimage = ([System.Drawing.Image]$bitmap)
        $Filename = (Join-Path $Tempdir.FullName "$($tempimage.Height).jpeg")
        $JpegEndocer = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|?{$_.FormatDescription -eq "JPEG"}

        $QL = [System.Drawing.Imaging.Encoder]([System.Drawing.Imaging.Encoder]::Quality)
        $EncoderParam = [System.Drawing.Imaging.EncoderParameters]::new(1)
        $EncoderParam.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new($QL,80L)

        $bitmap.Save($Filename,$JpegEndocer,$EncoderParam)
        # $tempimage.Save($Filename,[System.Drawing.Imaging.ImageFormat]::Jpeg,)
        $tempimage.Dispose()
    }
    
    
    Write-Information "Saving image dimentions reference to table"
    $Entity = Get-AzTableRowByPartitionKeyRowKey -Table $table -PartitionKey $TriggerMetadata.Name -RowKey "ImageDimentions"
    if($Entity)
    {
        Write-Information "Updating existing entity"
        $entity.value = ($Dimentions|ConvertTo-Json -AsArray)
        [void](Update-AzTableRow -Table $table -entity $Entity)
    }
    else {
        Write-Information "creating new entity"
        # $ContainerBaseUrl = "$($TriggerMetadata.BlobTrigger.split('/')[0])"
        [void](Add-AzTableRow -Table $table -PartitionKey $TriggerMetadata.Name -RowKey "ProfileBase" -property @{value="$($container.CloudBlobContainer.uri.tostring())/$($TriggerMetadata.Name)"} -Verbose)      
        [void](Add-AzTableRow -Table $table -PartitionKey $TriggerMetadata.Name -RowKey "ImageDimentions" -property @{value=($Dimentions|ConvertTo-Json -AsArray)} -Verbose)      
    }
    
    
    Write-Information "Uploading $($Dimentions.Count) files to blob"
    gci $Tempdir|%{
        [void]($Container|Set-AzStorageBlobContent -File $_.FullName -Blob "$($TriggerMetadata.Name)\$($_.name)" -Force)
    }
}
catch{
    throw $_
}

Write-Information "Removing $($TriggerMetadata.BlobTrigger)"
$Container|Remove-AzStorageBlob -Blob ($($TriggerMetadata.BlobTrigger.split('/')|select -Skip 1) -join "/") -Force
#Get Image Size
# Write-Information "$($item.BaseName): Getting image dimentions"
# $img = [System.Drawing.Image]::FromFile($item.FullName)


