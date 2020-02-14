@{
routeprefix=@{
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
    Message = "By default, az functions sets up 'site.com/Api/{endpoint}/{bindings}'. The 'API' part can be removed by defining a empty string in host.json#\http\routeprefix"
}
RegexInConstraint=@{
    #Whatever you want
    Scope = "HttpBinding"
    #Info, Warning, Error.. not used yet..
    Importance = "Warning"

    #Command will always return true of false. 
    #$Build_Function is global, but other variables is defined on the hashtable sent into the invoke-tooltips command
    Rules = @(
        @{
            Name = "Regex is defined in routing constraint"
            command = {$Routing -like "*:regex*"}
        }
    )
    Triggered = $false
    Message = "the check for regex constraint in route is really basic atm and might not function properly. If you get any errors regarding this you might concider adding -IgnoreRegexConstraintCheck . This will skip validation on route."
}

}
