<#
public static Bitmap ResizeImage(Image image, int width, int height)
{
    var destRect = new Rectangle(0, 0, width, height);
    var destImage = new Bitmap(width, height);

    destImage.SetResolution(image.HorizontalResolution, image.VerticalResolution);

    using (var graphics = Graphics.FromImage(destImage))
    {
        graphics.CompositingMode = CompositingMode.SourceCopy;
        graphics.CompositingQuality = CompositingQuality.HighQuality;
        graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
        graphics.SmoothingMode = SmoothingMode.HighQuality;
        graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;

        using (var wrapMode = new ImageAttributes())
        {
            wrapMode.SetWrapMode(WrapMode.TileFlipXY);
            graphics.DrawImage(image, destRect, 0, 0, image.Width,image.Height, GraphicsUnit.Pixel, wrapMode);
        }
    }

    return destImage;
}
#>
function Invoke-ResizeImage {
    [CmdletBinding()]
    [OutputType('System.Drawing.Bitmap')]
    param (
        [System.Drawing.Image]$Image,
        [int]$Size
    )
    
    begin {
        $destrect = [System.Drawing.Rectangle]::new(0,0,$Size,$Size)
        $destimg = [System.Drawing.Bitmap]::new($Size,$Size)

        #maintains DPI regardless of physical size -- may increase quality when reducing image dimensions or when printing
        $destimg.SetResolution($Image.HorizontalResolution,$Image.VerticalResolution)
    }
    
    process {
        $graphics = [System.Drawing.Graphics]::FromImage($destimg)
        #Compositing controls how pixels are blended with the background -- might not be needed since we're only drawing one thing. 

        #determines whether pixels from a source image overwrite or are combined with background pixels. SourceCopy specifies that when a color is rendered, it overwrites the background color.
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        #determines the rendering quality level of layered images
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        #determines how intermediate values between two endpoints are calculated
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        #specifies whether lines, curves, and the edges of filled areas use smoothing (also called antialiasing) -- probably only works on vectors
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        #affects rendering quality when drawing the new image
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        #prevents ghosting around the image borders -- 
        #naïve resizing will sample transparent pixels beyond the image boundaries, but by mirroring the image we can get a better sample (this setting is very noticeable)
        $wrapmode = [System.Drawing.Imaging.ImageAttributes]::new()
        $wrapmode.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)

        #draw image
        $graphics.DrawImage($Image,$destrect,0,0,$Image.Width,$Image.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrapmode)#
    }
    
    end {
        return $destimg
    }
}