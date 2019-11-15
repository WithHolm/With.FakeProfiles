Get-ChildItem $PSScriptRoot -Filter "*asset.ps1"|%{
    . $_.FullName
}
$InformationPreference = "Continue"
Write-Information "Setting Image Sizes"
# $Memorystream = [System.IO.MemoryStream]::new($InputBlob)
$temp = "C:\Users\Phil\source\repos\With.FakeProfiles\AzFunctions\FreshImage\Img"
gci -File -Path $temp|%{
    $Tempdir = new-item (Join-Path $temp $_.BaseName) -ItemType Directory -Force

    Write-Information $_.fullname
    $InputImage = [System.Drawing.Image]::FromFile($_.FullName)
    $Dimentions = @(90,256,512,$InputImage.Height)
    foreach($size in $Dimentions)
    {
        Write-Information "Setting size $size"
        # $Dimentions += $size
        $bitmap = Invoke-ResizeImage -Image $InputImage -Size $size
        $tempimage = ([System.Drawing.Image]$bitmap)
        $Filename = (Join-Path $Tempdir.FullName "$($tempimage.Height).jpeg")

        #set jpeg encoder
        $JpegEndocer = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|?{$_.FormatDescription -eq "JPEG"}

        #set quality
        $QL = [System.Drawing.Imaging.Encoder]([System.Drawing.Imaging.Encoder]::Quality)

        $EncoderParam = [System.Drawing.Imaging.EncoderParameters]::new(1)
        $EncoderParam.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new($QL,80L)
        $bitmap.Save($Filename,$JpegEndocer,$EncoderParam)
        # $tempimage.Save($Filename,[System.Drawing.Imaging.ImageFormat]::Jpeg,)
        $tempimage.Dispose()
    }
    $InputImage.Dispose()
}