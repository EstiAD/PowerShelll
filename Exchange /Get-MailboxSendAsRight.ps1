function Get-MailboxSendAsRight {
    <#
    .SYNOPSIS
    Retrieves a list of mailbox sendonbehalf permissions
    .DESCRIPTION
    Gathers a list of users with sendonbehalf permissions for a mailbox.
    .PARAMETER MailboxNames
    Array of mailbox names in string format.    
    .PARAMETER MailboxObject
    One or more mailbox objects.
    .LINK
    http://www.the-little-things.net   
    .NOTES
    Version
        1.0.0 01/25/2016
        - Initial release
    Author      :   Zachary Loeber

    .EXAMPLE
    Get-MailboxSendAsRight -MailboxName "Test User1" -Verbose

    Description
    -----------
    Gets the send-as permissions for "Test User1" and shows verbose information.

    .EXAMPLE
    Get-MailboxSendAsRight -MailboxName 'user1' | Format-List

    Description
    -----------
    Gets the send-as permissions for "user1" and returns the info as a format-list.

    .EXAMPLE
    (Get-Mailbox -Database "MDB1") | Get-MailboxSendAsRight | Where {$_.SendAs -notlike "S-1-*"}

    Description
    -----------
    Gets all mailboxes in the MDB1 database and pipes it to Get-MailboxSendAsRight and returns the 
    sendonbehalf permissions as an autosized format-table containing the Mailbox and sendonbehalf User.
    #>
    [CmdLetBinding(DefaultParameterSetName='AsString')]
    param(
        [Parameter(ParameterSetName='AsString', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [string]$MailboxName,
        [Parameter(ParameterSetName='AsMailbox', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [Microsoft.Exchange.Data.Directory.Management.Mailbox]$MailboxObject,
        [Parameter(HelpMessage='Includes unresolved names (typically deleted accounts).')]
        [switch]$ShowAll
    )
    begin {
        Write-Verbose "$($MyInvocation.MyCommand): Begin"
        $Mailboxes = @()
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'AsStringArray' {
                try {
                    $Mailboxes += Get-Mailbox $MailboxName -erroraction Stop
                }
                catch {
                    Write-Warning = "$($MyInvocation.MyCommand): $_.Exception.Message"
                }
            }
            'AsMailbox' {
               $Mailboxes += @($MailboxObject)
            }
        }
    }
    end {
        ForEach ($Mailbox in $Mailboxes) {
            Write-Verbose "$($MyInvocation.MyCommand): Processing Mailbox $($Mailbox.Name)"
            $sendasperms = @($Mailbox | Get-ADPermission | Where {($_.ExtendedRights -like "*send-as*") -and ($_.User -notlike 'NT AUTHORITY\SELF')})
            if ($sendasperms.Count -gt 0) {
                if ($ShowAll) {
                    $sendasperms = ($sendasperms).User
                }
                else {
                    $sendasperms = ($sendasperms | Where {$_.User -notlike 'S-1-*'}).User
                }
                New-Object psobject -Property @{
                    'Mailbox' = $Mailbox.Name
                    'SendAs' = $sendasperms
                }
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand): End"
    }
}
