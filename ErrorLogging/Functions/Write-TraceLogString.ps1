### Setting up Enum for $Severity parameter of Write-TraceLogString
$ENUM_WriteTraceLogString_Severity = @"
    namespace TraceLogString {
        public enum Severity {
            Information=1,
            Warning=2,
            Error=3,
            Verbose=4
        }
    }
"@

Add-Type -TypeDefinition $ENUM_WriteTraceLogString_Severity -Language CSharpVersion3

Function Write-TraceLogString {            

<#

.SYNOPSIS
    Returns a single line of a trace32/cmtrace log file as a string
.DESCRIPTION
    Having the log string construction abstracted from writing/appending data to a file allows us to easily pipe the log data to other functions, like Add-Content or Out-File, or even just print it directly to the console if you wanted.
.INPUTS
    None.  This function does not take pipeline input
.OUTPUTS
    [String].  This function returns a string value that is a single line of a trace32/cmtrace formatted log file.
.EXAMPLE
    PS C:\> $logString = Write-TraceLogString -Message "I am logging a message" -Component "MyScript.ps1" -Severity Information

    This command will return a log string to the $logString variable.  You could then pass that variable to Add-Content...

    PS C:\>Add-Content -Value $logString -Path "C:\temp\MyScript.log"
.EXAMPLE
    PS C:\> Write-TraceLogString -Message "There was an error" -Component "MyScript.ps1" -Severity Error | Out-File -FilePath C:\temp\MyScript.Log -Append -Encoding Default

    This command will write an Error line into the MyScript.Log file.  When piping to Out-File, you need to remember to use the -Append or -NoClobber switch parameters and set the encoding to "Default", or the file will not be formatted correctly
.PARAMETER Message
    This is the value that you want to appear in the "Log Text" column of a trace32/cmtrace log.
.PARAMETER Component
    This is the value that you want to appear in the "Component" column of a trace32/cmtrace log.
.PARAMETER Context
    Microsoft doesn't appear to use this field in their own trace32/cmtrace logs (at least not in SCCM logs).  We're going to
    store the running user's identity in this field.  This data is viewable if you open the log file with a text editor
.PARAMETER Severity
    This is an enum value.  Information=1, Warning=2, Error=3, Verbose=4.  You pass the name to the function and it substitutes the
    appropriate integer value in the trace32/cmtrace log string
.PARAMETER Thread
    This is the PID value
.PARAMETER File
    The file that generated the error.  In our case, this is most likely going to be the script file that generated the message.
.NOTES
    # Author:           Ryan Brown
    # Last Updated:     July 17, 2015
    # Module:           ErrorLogging.psm1

#>

    [CmdletBinding()]                          
    PARAM(                     
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Message,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Component,

        ### Even Microsoft's SCCM logs don't seem to use this field, we're going to store the running user's identity
        ### This only seems to be viewable in the raw-text of the .log file if you open it with a text editor
        [Parameter()]
        [string]$Context = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
  
        [Parameter(Mandatory=$true)]  
        [TraceLogString.Severity]$Severity,

        [Parameter()]
        [System.Int32]$Thread = [System.Threading.Thread]::CurrentThread.ManagedThreadId,

        ### This line looks complicated, but it's just grabbing the filename only from PSCommandPath and the line of the file, the output
        ### ends up looking like this:  MyFile.ps1:20
        [Parameter()]
        [string]$File = "$($MyInvocation.PSCommandPath.Substring($($MyInvocation.PSCommandPath.LastIndexOf('\'))+1)):$($MyInvocation.OffsetInLine)"
        
    )                                          

    Try {
    
        $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"                     
        $Time = Get-Date -Format "HH:mm:ss.fff"                     
        $Date = Get-Date -Format "MM-dd-yyyy"                     

    }
    
    Catch {

        Write-Error "Something went wrong will trying to calculate the Time Zone Bias, or while setting up date formatting."
        Write-Error $_.Exception.Message

    }

    Write-Verbose "Constructing log string...."      
    $logLine = "<![LOG[$Message]LOG]!>" +`
               "<" +`
               "time=`"$Time$($TimeZoneBias.bias)`" " +`
               "date=`"$Date`" " +`
               "component=`"$Component`" " +`
               "context=`"$Context`" " +`
               "type=`"$($Severity.value__)`" " +`
               "thread=`"$Thread`" " +`
               "file=`"$File`" "+`
               ">"
    Write-Verbose $logLine
    return $logLine

}