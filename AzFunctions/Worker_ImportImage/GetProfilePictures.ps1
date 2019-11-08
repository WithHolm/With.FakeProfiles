<#
.SYNOPSIS
Short description
.DESCRIPTION
Long description
.PARAMETER OutputFile
Path to jpeg file. can be ".jpeg" or ".jpg". if file already exist it will append int to the end of the file
.PARAMETER Amount
How many pictures do you want?
.PARAMETER WaitMultiplier
To test out the ratelimit for the site
.EXAMPLE
Get-RandomFace -OutputFile "Path\Picture.jpg"
.NOTES
General notes
#>


function Get-RandomFace {
    [CmdletBinding()]
    param(
        [parameter(HelpMessage="Select Path for outputfile. additional files will have numbers appended to the filename")]
        [System.IO.DirectoryInfo]$OutputFolder,

        [ValidateRange(1,999)]
        [Int]$Amount = 1,

        [ValidateRange(0,9)]
        [Int]$WaitMultiplier = 1.5,
        [switch]$passthru
    )    

    begin{
        $void = [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        if(!$OutputFolder.Exists)
        {
            Write-verbose "Parent directory does not exsist.. creating"
            new-item -Path $OutputFolder.FullName -ItemType Directory -Force|Out-Null
        }

        Write-Information "Saving images to  $($OutputFolder.FullName)"

        # Write-verbose "Directory: $($OutputFile.directory)"

        #Create and open runspace pool, setup runspaces array with min and max threads
        $pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS+1)
        # $pool.ApartmentState = "MTA"
        $pool.Open()
        $runspaces = @()
        

    }

    process {


        #Insert jobs to do in runspaces
        foreach($item in @(0..($Amount-1)))
        {
            #Add Content to Runspace
            $runspace = [PowerShell]::Create()
            [void]$runspace.AddScript({
                param([int]$Seconds)
                start-sleep -Seconds $($Seconds); 
                invoke-webrequest "https://thispersondoesnotexist.com/image" -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.96 Safari/537.36"
            })
            [void]$runspace.AddArgument(($item*$WaitMultiplier))
            $runspace.RunspacePool = $pool
            $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke();Processed=$false }
        }

        #While there is still items to be processed
        $Totalcount = @($runspaces).count
        Write-Information "Receiving Webcontent and writing to file ($Totalcount calls)"
        while ($runspaces.Processed -contains $false) {
            #Get items that are finished running and still not processed
            foreach ($RS in ($runspaces|?{$_.Status.IsCompleted -and !$_.Processed})) {

                # EndInvoke method retrieves the results of the asynchronous call
                $WebResponse = $RS.Pipe.EndInvoke($RS.Status)

                #Convert Bitarray to Image
                $Image = $([System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new($WebResponse.content)))
                
                #Figure out fileame for export. if filename is taken add filename1,filename2 etc untill it find one that doesent exist
                $TestFile = [System.IO.FileInfo](Join-Path $OutputFolder "$([guid]::NewGuid().Guid).jpeg")
                # $TestInt = 1
                # while($TestFile.exists)
                # {
                #     $Newname = "$BaseName$testint$Extension"
                #     $Testfile = [System.IO.FileInfo]$(join-path $OutputFile.Directory $Newname)
                #     $TestInt++
                # }

                #Save the file
                $Completedcount = @($runspaces|?{$_.Status.IsCompleted -and $_.Processed}).count +1
                Write-Information "Saving image to $($Testfile.fullname) ($($Completedcount.ToString().PadLeft($Totalcount.tostring().Length,"0"))/$Totalcount)"
                $Image.save($Testfile.fullname)
                if($passthru)
                {
                    Write-Output $TestFile
                }
                #Set processed and dispose current RS
                $RS.Processed = $true
                $RS.Pipe.Dispose()
            }
        }
    }
    end{
        #Cleanup
        $pool.Close() 
        $pool.Dispose()
    }
}

# Get-RandomFace -Amount 1 -OutputFile "$PSScriptRoot\test.jpeg"