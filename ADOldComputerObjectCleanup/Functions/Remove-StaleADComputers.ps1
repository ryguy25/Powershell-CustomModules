Function Remove-StaleADComputers {

<#
 .SYNOPSIS
    Removes old Active Directory machine acounts.
 .DESCRIPTION
    Called when a user invokes the Get-StaleADComputers function with the -Delete switch.  This function will receive
    an ArrayList of computer names from the Get-StaleADComputers function that will then be deleted from Active Directory
 .PARAMETER ComputerNames
    This parameter will take an ArrayList of computer names
#>    

[CmdletBinding()]
PARAM(

    [Parameter(Mandatory=$true)]
    [String[]]$ComputerNames

)
    
    Write-Verbose $script:logADOldComputerObjectCleanup
    $logFile = $script:logADOldComputerObjectCleanup
    
    ### Verify $logFile directory is a valid path.  If not, default to user's local %TEMP% directory
    if( ( Test-Path (Split-Path $logFile) ) -eq $false ) {
        
        Write-Error "$logFile does not exist or not available.  Defaulting to $env:TEMP"
        $logFile = "$env:TEMP\ADComputerObjectCleanup_$(Get-Date -Format "yyyy_MMMM_dd").log"
        Write-Verbose "Log File is:  $logFile"
    
    }

    ### Setup CONSTANT variables for use with Windows Forms
    $DIALOGRESULT_OK = [System.Windows.Forms.DialogResult]::OK
    $DIALOGRESULT_CANCEL = [System.Windows.Forms.DialogResult]::Cancel
    $COLOR_RED = [System.Drawing.Color]::Red

    ### FORM Setup
    $form = New-Object System.Windows.Forms.Form
    $form.Size = New-Object System.Drawing.Size(450,800)
    $form.Text = "Confirm Deletion"
    
    $labelWarning = New-Object System.Windows.Forms.Label
    $labelWarning.Location = New-Object System.Drawing.Size(10,20)
    $labelWarning.Size = New-Object System.Drawing.Size(280, 50)
    $labelWarning.ForeColor = $COLOR_RED
    $labelWarning.Text = "YOU ARE ABOUT TO DELETE THE FOLLOWING COMPUTER OBJECTS FROM ACTIVE DIRECTORY.  PLEASE REVIEW THE LIST CAREFULLY!"

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Size (10,70)
    $listBox.Size = New-Object System.Drawing.Size (280,650)
    $listBox.Sorted = $true

    ### Dynamically populate the listbox with computer names 
    foreach($computer in $ComputerNames) {  
    
        $listBox.Items.Add($computer) | Out-Null
    
    }

    $buttonConfirm = New-Object System.Windows.Forms.Button
    $buttonConfirm.Location = New-Object System.Drawing.Size(300,20)
    $buttonConfirm.Size = New-Object System.Drawing.Size(100,23)
    $buttonConfirm.Text = "Delete"
    $buttonConfirm.DialogResult = $DIALOGRESULT_OK
    $form.AcceptButton = $buttonConfirm

    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Location = New-Object System.Drawing.Size(300,45)
    $buttonCancel.Size = New-Object System.Drawing.Size(100,23)
    $buttonCancel.Text = "Cancel"
    $buttonCancel.DialogResult = $DIALOGRESULT_CANCEL
    $form.CancelButton = $buttonCancel

    $form.Controls.Add($labelWarning)
    $form.Controls.Add($buttonConfirm)
    $form.Controls.Add($buttonCancel)
    $form.Controls.Add($listBox)

    $form.TopMost = $true
    $dialogResult = $form.ShowDialog()

    Write-TraceLogString -Message "Deletion process start requested by $env:USERNAME" -Severity Information -Component "Information" | 
        Add-Content -Path $logFile

    if ( $dialogResult -eq $DIALOGRESULT_OK){

        foreach($computer in $ComputerNames){
            
            $delComp = Get-ADComputer -Identity $computer
            
            Try {
    
                Write-TraceLogString -Message "Deleting $delComp from Active Directory" -severity Information -Component "Information" |
                    Add-Content -Path $logFile
                Remove-ADObject -Identity $delComp -Recursive -Confirm:$false -ErrorAction SilentlyContinue
                
            }

            Catch {
            
                Write-TraceLogString -Message $_.Exception.Message -Severity Error -component "Remove-ADObject" |
                    Add-Content -Path $logFile
            
            }
    
        }

    }
    
    else {
        
        Write-TraceLogString -Message "Deletion canceled by $env:USERNAME" -Severity Information -Component "Information" |
            Add-Content -Path $logFile
    
    }
    
    Write-TraceLogString -Message "Deletion process completed" -Severity Information -component "Information" |
        Add-Content -Path $logFile
    $form.Dispose()

}