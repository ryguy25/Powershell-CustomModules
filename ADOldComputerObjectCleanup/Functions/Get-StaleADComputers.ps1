Function Get-StaleADComputers {

<#
 .SYNOPSIS
    Retrieves AD computer objects that have not changed their machine account passwords recently.
 .DESCRIPTION
    This function will retrieve a list of stale computer objects from Active Directory and then create a window to
    display the results.
    
    By default, it will target computer objects that are older than 30 days and that have not had their machine account 
    password updated in Active Directory in the last 120 days.

    Machine account passwords should change every 30 days as long as the computer is able to contact a domain
    controller.  Some good information about Machine Account passwords can be found at the following URL:
    http://blogs.technet.com/b/askds/archive/2009/02/15/test2.aspx
 .PARAMETER DaysSinceObjectCreated
    The number of days since the AD computer object was created.
    Default Value = 30
 .PARAMETER DaysSincePasswordChanged
    The number of days since the last machine account password change was recorded in Active Directory
    Default Value = 120
 .PARAMETER Delete
    When this switch is added on the command line, the resulting list is passed to the Delete-StaleADComputers function
    that is defined below.
 .EXAMPLE
    Get-StaleADComputers

    This example will return a window that displays a list of ADComputer objects that are more than 30 days old
    and that have not updated their machine account password in more than 120 days
 .EXAMPLE
    Get-StaleADComputers -Delete

    This example will return a window that displays a list of AD Computer objects that are more than 30 days old
    and that have not updated their machine account password in more than 120 days.  On the window, you will be able
    to select any number of computers that you would like to exclude from deletion.

    After clicking the Exclude Selected button, you will be prompted to review the list of remaining computer objects
    and then confirm that you wish to delete them from Active Directory
 .NOTES
#>

[CmdletBinding()]
PARAM(

    [Parameter()]
    [alias("Created")]
    [Int]$DaysSinceObjectCreated=30,

    [Parameter()]
    [alias("Deadline")]
    [Int]$DaysSincePasswordChange=120,

    [Parameter()]
    [switch]$Delete

)

    Write-Verbose "Get-StaleADComputers was called with the following parameter values:"
    Write-Verbose "`t`$DaysSinceObjectCreated   = $DaysSinceObjectCreated"
    Write-Verbose "`t`$DaysSincePasswordChanges = $DaysSincePasswordChange"
    Write-Verbose "`t`$Delete (switch)          = $Delete"

    ### Setup CONSTANT variables for use with Windows Forms
    $DIALOGRESULT_OK = [System.Windows.Forms.DialogResult]::OK
    $DIALOGRESULT_CANCEL = [System.Windows.Forms.DialogResult]::Cancel
    $SELECTIONMODE_MULTIEXTENDED = [System.Windows.Forms.SelectionMode]::MultiExtended
    
    ### Setup Variables
    $Today = [DateTime]::Today
    $Deadline = $Today.AddDays(-$DaysSincePasswordChange)
    $Created = $Today.AddDays(-$DaysSinceObjectCreated)
    $computerList = New-Object System.Collections.ArrayList

    ### Generate a list of computer accounts that are enabled and haven't had a machine account password
    ### change since $Deadline
    $oldComputerObjects = Get-ADComputer `
        -Filter {(PasswordLastSet -le $Deadline) -and (whenCreated -le $Created) -and (Enabled -eq $TRUE) -and (CN -like "*-*")} `
        -Properties PasswordLastSet,whenCreated -ResultSetSize $NULL | 
        Where-Object {($_.Name -notlike "SRV*") -and ($_.Name -notlike "MEDV*")}
    
    ### Store the computer name from each AD Computer Object into an ArrayList to add to the Windows Form ListBox
    foreach($object in $oldComputerObjects){
        
        $computerList.Add($object.Name) | Out-Null
    
    }

    ### FORM Setup
    $form = New-Object System.Windows.Forms.Form
    $form.Size = New-Object System.Drawing.Size(400,800)
    $form.Text = "Please review the list of computers:"

    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Size(10,10)
    $groupBox.Size = New-Object System.Drawing.Size(250,650)
    $groupBox.Text = "Stale AD Machine Objects"
    
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Size (10,20)
    $listBox.Size = New-Object System.Drawing.Size (230,630)
    $listBox.Sorted = $true
    $listBox.SelectionMode = $SELECTIONMODE_MULTIEXTENDED

    foreach($computer in $computerList) {
    
        $listBox.Items.Add($computer) | Out-Null
    
    }
    
    $buttonExclude = New-Object System.Windows.Forms.Button
    $buttonExclude.Location = New-Object System.Drawing.Size(280,45)
    $buttonExclude.Size = New-Object System.Drawing.Size(100,23)
    $buttonExclude.Text = "Exclude Selected"
    $buttonExclude.DialogResult = $DIALOGRESULT_OK
    $form.AcceptButton = $buttonExclude

    $buttonClose = New-Object System.Windows.Forms.Button
    $buttonClose.Location = New-Object System.Drawing.Size(280,20)
    $buttonClose.Size = New-Object System.Drawing.Size(100,23)
    $buttonClose.Text = "Close"
    $buttonClose.DialogResult = $DIALOGRESULT_CANCEL
    $form.CancelButton = $buttonClose

    $form.Controls.Add($groupBox)
        
    #We only want the "Exclude" button if we are deleting objects
    if($Delete.IsPresent) {  
        
        $form.Controls.Add($buttonExclude)
    
    }
        
    $form.Controls.Add($buttonClose)
    $groupBox.Controls.Add($listBox)

    $form.TopMost = $true
    $dialogResult = $form.ShowDialog()

    switch ($dialogResult) {
        
        $DIALOGRESULT_OK ################################################################################

                            {

                                $excludeComputers = $listBox.SelectedItems
                                
                                foreach ($exclude in $excludeComputers) {

                                    $computerList.Remove($exclude)

                                }

                                if ($Delete.IsPresent) {

                                    Write-Verbose "User requested deletion.  Passing `$computerList to Remove-StaleADComputers"
                                    
                                    if ( $PSBoundParameters.ContainsKey('Verbose') ) {

                                        Remove-StaleADComputers -ComputerNames $computerList -Verbose

                                    }
                                    
                                    else {
                                               
                                        Remove-StaleADComputers -ComputerNames $computerList 

                                    }
                                               
                                }
                                
                                else {
                                               
                                    $form.Dispose()
                                    return $computerList
                                               
                                }

                            }

        $DIALOGRESULT_CANCEL ############################################################################

                            {

                                $form.Dispose()
                                Write-Verbose "User clicked 'Close'.  No further action taken"
                                return $computerList
                
                            }

        default #########################################################################################

                            {

                                $form.Dispose()
                                return $computerList

                            }

    }   

}