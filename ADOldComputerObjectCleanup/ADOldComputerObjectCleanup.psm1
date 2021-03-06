### You may optionally change the logging location of this module by loading it manually with the -ArgumentList parameter
### PS C:\> Import-Module -Name ADOldComputerObjectCleanup -ArgumentList "C:\Temp\Cleanup.log" -Force

PARAM(

    [string]$logADOldComputerObjectCleanup = "$PSScriptRoot\Logs\ADComputerObjectCleanup$(Get-Date -Format "yyyy_MMMM_dd").log"

)

#region OLD ASSEMBLY IMPORTS

#Import-Module ActiveDirectory -Cmdlet "Get-ADComputer","Remove-ADObject"
#Add-Type -AssemblyName System.Windows.Forms
#Add-Type -AssemblyName System.Drawing

#endregion

#region Function Imports

. $PSScriptRoot\Functions\Get-StaleADComputers.ps1
. $PSScriptRoot\Functions\Remove-StaleADComputers.ps1

#endregion

Export-ModuleMember -Function * -Cmdlet * -Variable *

<#
Function Write-Log{            
##----------------------------------------------------------------------------------------------------            
##  Function: Write-Log            
##  Purpose: This function writes trace32 log fromat file to user desktop      
##  Function by: Kaido Järvemets Configuration Manager MVP (http://www.cm12sdk.net)
##----------------------------------------------------------------------------------------------------                            
PARAM(                     
    [String]$Message,  
    [String]$Path = "$env:USERPROFILE\Documents\ADComputerObjectCleanup.log",                                 
    [int]$severity,                     
    [string]$component
)                                          
    
    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"                     
    $Date= Get-Date -Format "HH:mm:ss.fff"                     
    $Date2= Get-Date -Format "MM-dd-yyyy"                     
    $type=1                         
    
    "<![LOG[$Message]LOG]!><time=$([char]34)$date+$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default            
}
#>   