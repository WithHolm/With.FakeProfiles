@{
    Project = @{
        Pipeline = "Dev"
        Name = "FakeProfiles"
        ConfigName = "Config"
        #Config should never be more than 2 levels
        Azconfig = @{
            ImageImport = @{
                #Biggest batch to import from internet
                MaxBatch = 10
                #Folder to use dusing import
                Folder = "Import"
            }
            Resize = @{
                #Dimensions to save image as
                Dimension = @(90,256,512,1024)
                #0-100, Higher means better, but bigger size cost
                Quality=80
            }
            Image = @{
                Container="Pictures"
                #Biggest batch to import from internet
                ImportMaxBatch = 10
                #Dimensions to save image as
                Dimension = @(90,256,512,1024)
                #Folder to use dusing import
                ImportFolder = "Import"
                #Folder to use when storig profilefolder
                Storage = "Store"
                #0-100, Higher means better, but bigger size cost
                Quality=80
            }
            AI = @{
                FaceAttributes = @("age","gender","smile","glasses","hair","facialHair")
                CallsPerMinute = 10
                ShouldBePresent = @(
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
            }
        }
    }
    Az = @{
        TenantName = "Meholm.com"
        SubscriptionName = "VSE"
        Location = "Westeurope"
        Resources = @{
            ResourceGroup = @{
                Name = "{Pipeline}-{Options.Project.Name}-RG"
            }
            Functions = @{
                Name = "{Pipeline}{Options.Project.Name}FN"
                LocalPath = "AzFunctions"
                #How many threads do you want to run at once max for the function runspace? 1-10
                Concurrencycount = 10
            }
            StorageAccount = @{
                #Select a random number at the end here..
                Name = "{Pipeline}{Options.Project.Name}SA"
                Sku = "Standard_LRS"
                Tables = @(
                    "Config"
                    "Faces",
                    "Progress"
                    "Import"
                )
                Queues = @(
                )
                Containers = @(
                    "pictures"
                )
            }
            AppservicePlan = @{
                Name = "{Pipeline}-{Options.Project.Name}-ASP"
            }
            CognitiveServices_Face = @{
                Name = "{Pipeline}-{Options.Project.Name}-FaceCS"
            }
        }
    }
    Powershell = @{
        RequiredModules = @{
            az = "2.8.*"
            azTable = "2.0.*"
            pscognitiveservice = "0.4.*"
        }
    }
}