@{
    Project = @{
        Pipeline = "Dev"
        Name = "FakeProfiles"
        Azconfig = @{
            Image = @{
                ImageDimensions = @(90,256)
                MaxImages = 2000
            }
            AI = @{
                CallsPerMinute = 20
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