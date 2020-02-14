function Get-HttpRouteConstraint {
    [CmdletBinding()]
    param (
    )
    
    begin {
    }
    
    process {
        @(
            @{
                Constraint = "alpha"
                Description = "Matches uppercase or lowercase Latin alphabet characters (a-z, A-Z)"
                Example = "{x:alpha}"
            },
            @{
                Constraint = "bool"
                Description = "Matches a Boolean value."
                Example = "{x:bool}"
            },
            @{
                Constraint = "datetime"
                Description = "Matches a DateTime value."
                Example = "{x:datetime}"
            },
            @{
                Constraint = "decimal"
                Description = "Matches a decimal value."
                Example = "{x:decimal}"
            },
            @{
                Constraint = "double"
                Description = "Matches a 64-bit floating-point value."
                Example = "{x:double}"
            },
            @{
                Constraint = "float"
                Description = "Matches a 32-bit floating-point value."
                Example = "{x:float}"
            },
            @{
                Constraint = "guid"
                Description = "Matches a GUID value."
                Example = "{x:guid}"
            },
            @{
                Constraint = "int"
                Description = "Matches a 32-bit integer value."
                Example = "{x:int}"
            },
            @{
                Constraint = "length"
                Description = "Matches a string with the specified length or within a specified range of lengths."
                Example = "{x:length(6)} {x:length(1,20)}"
            },
            @{
                Constraint = "long"
                Description = "Matches a 64-bit integer value."
                Example = "{x:long}"
            },
            @{
                Constraint = "max"
                Description = "Matches an integer with a maximum value."
                Example = "{x:max(10)}"
            },
            @{
                Constraint = "maxlength"
                Description = "Matches a string with a maximum length."
                Example = "{x:maxlength(10)}"
            },
            @{
                Constraint = "min"
                Description = "Matches an integer with a minimum value."
                Example = "{x:min(10)}"
            },
            @{
                Constraint = "minlength"
                Description = "Matches a string with a minimum length."
                Example = "{x:minlength(10)}"
            },
            @{
                Constraint = "range"
                Description = "Matches an integer within a range of values."
                Example = "{x:range(10,50)}"
            },
            @{
                Constraint = "regex"
                Description = "Matches a regular expression."
                Example = "{x:regex(^\d{3}-\d{3}-\d{4}$)}"
            }
        )
    }
    
    end {
        
    }
}

# alpha 	Matches uppercase or lowercase Latin alphabet characters (a-z, A-Z) 	{x:alpha}
# bool 	Matches a Boolean value. 	{x:bool}
# datetime 	Matches a DateTime value. 	{x:datetime}
# decimal 	Matches a decimal value. 	{x:decimal}
# double 	Matches a 64-bit floating-point value. 	{x:double}
# float 	Matches a 32-bit floating-point value. 	{x:float}
# guid 	Matches a GUID value. 	{x:guid}
# int 	Matches a 32-bit integer value. 	{x:int}
# length 	Matches a string with the specified length or within a specified range of lengths. 	{x:length(6)} {x:length(1,20)}
# long 	Matches a 64-bit integer value. 	{x:long}
# max 	Matches an integer with a maximum value. 	{x:max(10)}
# maxlength 	Matches a string with a maximum length. 	{x:maxlength(10)}
# min 	Matches an integer with a minimum value. 	{x:min(10)}
# minlength 	Matches a string with a minimum length. 	{x:minlength(10)}
# range 	Matches an integer within a range of values. 	{x:range(10,50)}
# regex 	Matches a regular expression. 	{x:regex(^\d{3}-\d{3}-\d{4}$)}