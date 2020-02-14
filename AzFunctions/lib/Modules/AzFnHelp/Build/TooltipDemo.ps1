#The basic gist is that you want to convey messages to the developer, but only on certain triggers and possibly only one time
#So -> 

#First load module azfnhelp
ipmo ([System.IO.DirectoryInfo]$PSScriptRoot).Parent.FullName

# #Define basics
$Global:Build_Function = @{
    WorkingDirectory = $WorkingDirectory.FullName
    ModulePath = ""
    Hostconfig = @{
        Version = 2.0
        Logging = @{
            fileLoggingMode = "debugOnly"
        }
        http = @{
            routeprefix = "test"
        }
    }
    Functions = @{}
    TooltipPreference = "Continue"
}

# #define the rule
$Global:Build_Function.tooltips = @{
    "routeprefix"=@{
        #Whatever you want
        Scope = "HttpBinding"
        #Info, Warning, Error.. not used yet..
        Importance = "Info"

        #Command will always return true of false. 
        #$Build_Function is global, but other variables is defined on the hashtable sent into the invoke-tooltips command
        Rules = @(
            @{
                Name = "Binding has route defined"
                command = {![string]::IsNullOrEmpty($binding.Route)}
            },
            @{
                Name = "Host.json does not contains http.routeprefix"
                Command = {$Build_Function.hostconfig.http.routeprefix -ne ""}
            }
        )
        Triggered = $false
        Message = "By default, az functions sets up 'site.com/Api/{endpoint}/$($binding.route)'. The 'API' part can be removed by defining a empty string in host.json#\http\routeprefix"
    }
}

# #The actual code that should be defined in the cmdlet
$binding = @"
{
    "name": "Request",
    "type": "Http",
    "direction": "In",
    "authLevel": "admin",
    "Methods": [],
    "route": "test/test"
}
"@|ConvertFrom-Json

#This should trigger the defined message
Invoke-Tooltips -scope "httpbinding" -Variables @{Binding=$binding}
#WARNING: By default, az functions sets up 'site.com/API/{endpoint}/test/test'. The 'API' part can be removed by defining a empty string in host.json#\http\routeprefix

#The message should not be triggered a second time
Invoke-Tooltips -scope "httpbinding" -Variables @{Binding=$binding}


