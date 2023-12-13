# Change these to suit your needs
$BatchSize = 200        # Maximum number of mailboxes per batch
$BadItemLimit = 10      # Maximum allowed bad items per batch
$BatchBaseName = 'MailboxBatch'    # Base file name for csv and import files
$SourceServer = 'Exchange'  # target specific server to remove mailbox results for already migrated mailboxes
$SourceDatabase = "*Seventh*" # Target specific source mailbox databases
[string]$DestDBs = 'DB01,DB02,DB03,DB04,DB05,DB06'    # Migrate the mailboxes to these databases (round robin)

# Don't change these
$CurrentPath = (pwd).Path
$CurrentBatch = 0
$CurrentBatchEmails = @()

$BatchCommand = @'
New-MigrationBatch -Local -Name @0@ -CSVData ([System.IO.File]::ReadAllBytes("@1@\@0@.csv")) -TargetDatabases @2@ -BadItemLimit @3@
'@
$BatchImportFileName = "$($BatchBaseName)_Import.txt"

$Mailboxes = Get-Mailbox -ResultSize Unlimited -Server $SourceServer | Where {$_.Database -like $SourceDatabase}
$Mailboxes | Foreach {    
    $CurrentBatchEmails += $_
    if ($CurrentBatchEmails.Count -ge $BatchSize)
    {
        $BatchName = "$($BatchBaseName)_$($CurrentBatch)"
        $tmpCommand = $BatchCommand -replace '@0@',$BatchName `
                                    -replace '@1@',$CurrentPath `
                                    -replace '@2@',$DestDBs `
                                    -replace '@3@',$BadItemLimit
        Out-File $BatchImportFileName -Append -InputObject $tmpCommand
        $CurrentBatchEmails | 
            Select @{n='EmailAddress';e={$_.PrimarySMTPAddress}} | 
                Export-Csv -NoTypeInformation "$($BatchName).csv"
        $CurrentBatch++
        $CurrentBatchEmails = @()
    }
}

# Process the last batch of mailboxes if there are any
if ($CurrentBatchEmails.Count -gt 0)
{
    $BatchName = "$($BatchBaseName)_$($CurrentBatch)"
    [string]$tmpCommand = $BatchCommand -replace '@0@',$BatchName `
                                        -replace '@1@',$CurrentPath `
                                        -replace '@2@',$DestDBs `
                                        -replace '@3@',$BadItemLimit
    Out-File $BatchImportFileName -Append -InputObject $tmpCommand
    $CurrentBatchEmails | 
        Select @{n='EmailAddress';e={$_.PrimarySMTPAddress}} | 
            Export-Csv -NoTypeInformation "$($BatchName).csv"
}
