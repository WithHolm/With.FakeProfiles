# Input bindings are passed in via param block.
param([byte[]] $InputBlob, $TriggerMetadata)

import-module "az.storage"
import-module pscognitiveservice
$TableName = "Faces" 
$HashName = "MD5"
$AIRounds = 2
$StorageBlob = "pictures"
$tempfolder = "$env:temp\json\$($TriggerMetadata.name)"


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

# Write out the blob name and size to the information log.
Write-Host "PowerShell Blob trigger function Processed blob! Name: $($TriggerMetadata.Name) Size: $($InputBlob.Length) bytes"

$cs = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($env:AzureWebJobsStorage)
Write-Information "Connecting to storageaccount '$($CS.credentials.AccountName)'"
$sa = Get-AzStorageAccount|Where-Object{$_.StorageAccountName -eq $CS.credentials.AccountName}
$container = $sa|Get-AzStorageContainer -name $StorageBlob
$table = Get-AzTableTable -storageAccountName $sa.StorageAccountName -TableName $TableName -resourceGroup $sa.ResourceGroupName

$Faces = @()
$workers = @()
for ($i = 0; $i -lt $AIRounds; $i++) {
    $Faces += get-face -URL $TriggerMetadata.uri -FaceAttributes age,gender,smile,glasses,hair,facialHair

    $ShouldBePresent = @(
        "age",
        "gender",
        "smile",
        "facialhair.moustache",
        "facialhair.beard",
        "facialhair.sideburns",
        "glasses",
        "hair.bald"
        "hair.invisible"
        "hair.hairColor"
    )
    $test = $true
    foreach($Present in $ShouldBePresent)
    {
        $Check = ""
        $Present.split('.')|%{
            $Check = $Present.$_
        }
        
        if([string]::IsNullOrEmpty($Check))
        {   
            $Test = $false
        }
    }

    $string = $face|ConvertTo-Json -Depth 10
    $StringBuilder = New-Object System.Text.StringBuilder 
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{ 
        [Void]$StringBuilder.Append($_.ToString("x2")) 
    } 
    $hash = $StringBuilder.ToString() 
    #Save
    $FileName = "pic_data_$hash.json"
    $Filepath = (Join-Path $tempfolder $FileName)
    if(!(test-path $Filepath))
    {
        [void](new-item $Filepath -ItemType File -Force -Value $string)
    }
    else {
        write-warning "there is already the same data for this person"
        continue
    }

    #Quit if it has all datapoints
    if($test -eq $false)
    {
        Write-warning "There should be more collections for this person"
        continue
    }
    else 
    {
        $i = $AIRounds
    }

    <#
    {
        "faceRectangle": {
        "top": 323,
        "left": 211,
        "width": 598,
        "height": 598
        },
        "faceAttributes": {
        "smile": 0.654,
        "headPose": {
            "pitch": -12.5,
            "roll": 1.6,
            "yaw": 12.6
        },
        "gender": "male",
        "age": 30.0,
        "facialHair": {
            "moustache": 0.1,
            "beard": 0.1,
            "sideburns": 0.1
        },
        "glasses": "NoGlasses",
        "emotion": {
            "anger": 0.0,
            "contempt": 0.001,
            "disgust": 0.0,
            "fear": 0.0,
        "happiness": 0.654,
            "neutral": 0.345,
            "sadness": 0.0,
            "surprise": 0.0
        },
        "blur": {
            "blurLevel": "low",
            "value": 0.11
        },
        "exposure": {
        "exposureLevel": "goodExposure",
            "value": 0.75
        },
        "noise": {
            "noiseLevel": "low",
            "value": 0.16
        },
        "makeup": {
            "eyeMakeup": true,
            "lipMakeup": false
        },
        "accessories": [],
        "occlusion": {
            "foreheadOccluded": false,
            "eyeOccluded": false,
            "mouthOccluded": false
        },
        "hair": {
            "bald": 0.04,
            "invisible": false,
            "hairColor": [
            {
            "color": "brown",
                "confidence": 1.0
            },
            {
                "color": "black",
                "confidence": 0.56
            },
            {
                "color": "blond",
                "confidence": 0.29
            },
            {
                "color": "red",
                "confidence": 0.25
            },
            {
                "color": "gray",
                "confidence": 0.22
            },
            {
                "color": "other",
                "confidence": 0.05
            }
            ]
            }
        }
    }
    #>
}

#Fix age
# if(@($Faces.gender|select -Unique).count -gt 1)
# {
# }
$Face = @{
    age = [math]::Round((($Faces.age|Measure-Object -Sum).sum / @($Faces).Count))
    gender = $Faces.gender[0]
    smile = [math]::Round((($Faces.smile|Measure-Object -Sum).sum / @($Faces).Count),2)
    facialhair = @{
        moustache  = [math]::Round((($Faces.facialhair.moustache|Measure-Object -Sum).sum / @($Faces).Count),2)
        beard = [math]::Round((($Faces.facialhair.moustache|Measure-Object -Sum).sum / @($Faces).Count),2)
        sideburns = [math]::Round((($Faces.facialhair.moustache|Measure-Object -Sum).sum / @($Faces).Count),2)
    }
    glasses = ($Face[0].glasses -ne "Noglasses")
    hair = @{
        bald = [math]::Round((($Faces.facialhair.moustache|Measure-Object -Sum).sum / @($Faces).Count),2)
        invisible = $Face.hair.invisible[0]
        hairColor = @(($Face.hair.hairColor|?{$_.confidence -gt 0.50}).color)
    }

}

$k|ConvertTo-Json -Depth 10|Out-File (Join-Path $tempfolder "pic_data.json")
$table

gci $tempfolder -File|%{
    $AzName = "Import\$($_.name)"
    Write-Information "Uploading $($_.name) to blob '$($SA.StorageAccountName)':'$AzName'"
    $ref = $container.CloudBlobContainer.GetBlockBlobReference($AzName)
    $ref.Properties.ContentType = "application/octet-stream"
    $workers += $ref.UploadFromFileAsync($_.fullname)
}

while($false -in $workers.IsCompleted)
{
    Write-Information "Waiting for blobupload ($(@($workers|?{$_.iscompleted}).count)/$($workers.Count))"
    Start-Sleep -Milliseconds 500
}
gci $LocalStorage|remove-item -Force -Recurse
