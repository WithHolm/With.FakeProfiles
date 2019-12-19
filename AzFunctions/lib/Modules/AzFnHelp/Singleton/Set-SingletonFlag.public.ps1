using namespace Microsoft.Azure.Storage
function Set-FnSingletonFlag
{
    [CmdletBinding()]
    [outputtype([boolean])]
    param (
        [parameter(Mandatory)]
        [String]$Name,
        [parameter(Mandatory)]
        [String]$ConnectionString,

        [parameter(ParameterSetName = "Enable", Mandatory)]
        [Switch]$Enable,
        [parameter(ParameterSetName = "Enable")]
        [int]$TimeoutSec = (10*60),

        [parameter(ParameterSetName = "Disable", Mandatory)]
        [Switch]$Disable
    )
    
    begin
    {   
        $PeekMessageCount = 32
        $SleepMiliseconds = 5
        $Ticks = [datetime]::Now.Ticks
        $Queue = Get-FnQueueFast -Connectionstring $ConnectionString -Name "singleton-$Name" -CreateIfNotExist
        $ID = Get-SingletonID
        Write-verbose "Singleton ID is '$ID'"
    }
    
    process
    {
        if ($Enable)
        {
            $return = $false
            try{
                $RunID = Get-SingletonID -ReturnRunID
                $Messages = @((Get-FnQueuePeek -Queue $Queue).AsString)
    
                if($Messages|Where-Object{$_ -like "Lock-$RunID-*"})
                {
                    Write-Verbose "True! There was already a lock inplace for this RunID: '$RunID'"
                    #setting $return to true means im going to write another lock message
                    # $return = $true
                    return $true
                }

                if($Messages|Where-Object{$_ -like 'Lock-*'})
                {
                    Write-Verbose "False! There is another instance locking:'$($Messages|Where-Object{$_ -like 'Lock-*'})'"
                    $return = $false
                    return $false
                }

                
                #Create Test QMessage and wait
                Write-Debug "Creating testing message, Longevity: $($SleepMiliseconds * 1000)Ms"
                New-FnQueueMessage -Data "Test-$ID" -Queue $queue -MessageLongevity ([timespan]::FromMilliseconds($SleepMiliseconds * 1000))
                Start-Sleep -Milliseconds ($SleepMiliseconds*10)
    
                #Get QMessages
                $Messages = @((Get-FnQueuePeek -Queue $Queue).AsString)
    
                if($Messages|Where-Object{$_ -like 'Lock*'})
                {
                    Write-Verbose "False! There is another instance locking:'$($Messages|Where-Object{$_ -like 'Lock-*'})'"
                    $return = $false
                    return $false
                }
    
                if(($Messages|Where-Object{$_ -like "Test*"}).Count -le 1)
                {
                    Write-Verbose "True! There was no challengers for the singleton. Locking"
                    $return = $true
                    return $true
                }
    
    
                #Test Ticks
                #Test-RunID-Ticks-RandomNumber
                $CompetitionTicks = @(($Messages|?{$_ -notlike "*$ID"}|%{$_.split("-")[2]}))
    
                #If there is a higher tick
                if($CompetitionTicks|Where-Object{$_ -lt $Ticks})
                {
                    Write-verbose "False! There was another instace test that came before me"
                    $return = $false
                    return $false
                }

                #If all other ticks are lower
                elseif(@($CompetitionTicks|Where-Object{$_ -gt $Ticks}).count -eq $CompetitionTicks)
                {
                    Write-Verbose "True! No other instances came before me"
                    $return = $true
                    return $true
                }
    
                #Test Random Number
                #Test-RunID-Ticks-RandomNumber
                $CompetitionNumbers = @(($Messages|?{$_ -notlike "*$ID" -and $_ -like "*-$Ticks-*"}|%{$_.split("-")[-1]}))
    
                #If there is a higher number
                if($CompetitionNumbers|Where-Object{$_ -gt $Ticks})
                {
                    Write-verbose "False! The othe instances had higher random number than me.."
                    $return = $false
                    return $false
                }
                elseif($CompetitionNumbers|Where-Object{$_ -eq $Ticks})
                {
                    $return = $false
                    Throw "There was two instances that was called at the EXACT same time and got the exact same random number (0-999999).. how bout that, huh?"
                    # return $false
                }

                Write-verbose "True! All checks completed"
                $return = $true
                return $true
            }
            catch{
                $return = $false
                Write-Error $_
                # return $false
            }
            finally{
                if($return -eq $true)
                {
                    Write-Verbose "Setting singleton lock on queue '$($Queue.Name)'"
                    New-FnQueueMessage -Queue $Queue -Data "Lock-$ID" -MessageLongevity ([timespan]::FromSeconds($TimeoutSec))
                }
            }
        }
        elseif ($Disable)
        {
            $LockMsg = (Get-FnQueuePeek -Queue $Queue -count 32)
            :Locksearch for ($i = 0; $i -lt @($LockMsg).count; $i++) {
                if($LockMsg[$i].AsString -like "Lock-$RunID*")
                {
                    break :Locksearch
                }
                #
            }

            Write-Verbose "Getting $($i+1) items from queue, to get lockmessage"
            $Msg = $Queue.GetMessages(($i+1),([timespan]::FromMilliseconds(10)))
            $msg|?{$_.AsString -like "Lock-$RunID*"}|%{
                Write-Information "Removing singleton lock on queue '$($Queue.Name)' -> '$($_.AsString)'"
                $Queue.DeleteMessage($_)
            }
        }
    }
    end {
            
    }
}