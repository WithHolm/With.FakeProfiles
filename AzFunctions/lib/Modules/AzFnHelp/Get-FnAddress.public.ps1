function Get-FnAddress {
    [CmdletBinding()]
    param (
        $Name
    )
    
    begin {
        
    }
    
    process {
        $path = [System.IO.FileInfo](Get-PSCallStack)[1].ScriptName
        $path = $path.Directory
        while(!(gci $path.FullName -Filter "Host.json" -File))
        {
            $path = $path.Parent
        }

        $path.FullName
        $FunctionFolders = gci  $path.FullName -Directory
        if($name -notin $FunctionFolders.Name)
        {
            Throw "Cannot find Function '$Name': $($FunctionFolders.name -join ",")"
        }

        if($env:WEBSITE_HOSTNAME -like "*localhost*")
        {
            return "http://$env:WEBSITE_HOSTNAME/api/$name"
        }
        else{
            return "https://$($env:WEBSITE_HOSTNAME)/api/$name"
        }

    }
    
    end {
        
    }
}