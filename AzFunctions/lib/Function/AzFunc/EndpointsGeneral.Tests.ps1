Describe "Testing endpoints"{
    $Root = [System.IO.DirectoryInfo]$PSScriptRoot
    While(!$Root.GetFiles("host.json"))
    {
        $root = $Root.Parent
    }
    Write-host "Root: '$($Root.FullName)'"
    $ModulePath = Join-Path $Root.FullName "Lib"
    # $ModuleFnReference = (Get-ChildItem -Filter "*.psm1" -Path $ModulePath).FullName.Replace($Root.FullName,"..").Replace()

    Write-Host $ModuleFnReference
    Gci $Root.FullName -Directory|?{gci $_ -filter "function.json"}|%{
        $fn = Get-Content (Join-Path $_.FullName "Function.json") -Raw|ConvertFrom-Json
        
        it "<FunctionName> Has reference to module" -TestCases @{
            FunctionName = $_.BaseName
        }{
            $fn.scriptFile|should -Not -BeNullOrEmpty
        }

        if(![string]::IsNullOrEmpty($fn.scriptFile))
        {
            It "<FunctionName> References a module file module"-TestCases @{
                FunctionName = $_.BaseName
            }{
                test-path (join-path $root.FullName $fn.scriptFile.tostring().Replace("..",''))|should be $true
            }
        }
        # write-host $_.FullName
    }
    # $Items = get-childitem 
    # $Items = get-childitem -Recurse -Include "*.Qtrigger.ps1","*.Http.ps1","*.Blobtrigger.ps1"
    # Foreach($item in $items)
    # {
    #     it "Is defined "
    #     # It ""
    # }
}