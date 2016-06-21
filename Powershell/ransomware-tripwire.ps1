<#
.Synopsis
   This script monitors 'tripwire' files to see if they have been renamed, deleted or modified by a potential ransomware virus
.DESCRIPTION
   You should run this script as a service on a suitable Windows server. 
   It will take a set (array) of tripwire files and compare those to reference (read-only) files to make sure the files match, i.e. to make sure the tripwire files haven't been modified
   If the script either:
   
   - cannot access the tripwire or reference files
   OR
   - detects the tripwire and reference files are different
   
   It will alert the appropriate IT Support team(s)
.EXAMPLE
   ./ransomware-trip-simple-many-az-files.ps1
.EXAMPLE
   <path-to-script>/ransomware-trip-simple-many-az-files.ps1
#>

######### Start of all the preliminary stuff #########

## Setup a variable to represent newline
$nl = "`r`n"

Write-Output "----------------------------------------------------- `
            ${nl}Starting Ransomware monitoring script for Groupshares `
            ${nl}-----------------------------------------------------"

$ErrorActionPreference = "Stop"

## Check to see if J drive exists, if not map it to the groupshares DFS address
Write-Output "${nl}Mounting the J drive for scanning${nl}"
If (!(Test-Path J:)) {
    New-PSDrive -Name J -PSProvider FileSystem –Root "C:\Tripwire Files"
}
Write-Output "${nl}"

## future improvement - could parameterise the $tripwireAfiles & $tripwireZfiles arrays
## Setup the various tripwire and reference files 
$tripfileA1 = "J:\Directory1\a-dont-modify.docx"
$tripfileA2 = "J:\Directory2\a-dont-modify.docx"
$tripwireAfiles = @($tripfileA1,$tripfileA2)

$tripfileZ1 = "J:\Directory1\z-dont-modify.docx"
$tripfileZ2 = "J:\Directory2\z-dont-modify.docx"
$tripwireZfiles = @($tripfileZ1,$tripfileZ2)

$reffileA = "J:\Reference\a-dont-modify.docx"
$reffileZ = "J:\Reference\z-dont-modify.docx"

######### End of all the preliminary stuff #########

## Send-Mail function
function Send-Mail 
{
    [CmdletBinding()]
    Param ($source, $to)
    $smtpServer = "mailrelay-cup.internal"
    $smtpFrom = "virus-monitor-donotreply@cambridge.org"
    $smtpTo = $to

    $messageSubject = $source[0]
    $message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
    $message.Subject = $messageSubject
    $message.IsBodyHTML = $false
    $message.Body = $source[1]

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($message)
}

## Check-FileAccess function
function Check-FileAccess 
{
    [CmdletBinding()]
    Param ($reffile, $tripwirefiles) 
    ## Check access to the reference & tripwire files content
    try {
	    $refcontent = Get-Content $reffile
        For ($i=0; $i -lt $tripwirefiles.Length; $i++) {
		    $tripfile = $tripwirefiles[$i]
		    $tripcontent = Get-Content $tripfile
	    }	
        Write-Verbose "Check-FileAccess function has successfully run, files were accessed and content was obtained"
    }
    catch {
        ## Probably a file not found or permissions error
        Write-Verbose "Check-FileAccess function failed, most likely due to a file not found or permissions error"
        $body2 = "${nl}${nl}Tripwire file is: $tripfile `
                  ${nl}Reference file is: $reffile `
                  ${nl}${nl}Please restart the ransomware-tripwire service on infra-admin.ad.cambridge.org after resolving this issue"
        $body = -join ($body1FileAccess, $body2)
        Write-Output "$body `
                      ${nl}-------------------------------------------------------- `
                      ${nl}Exiting the Ransomware monitoring script for Groupshares `
                      ${nl}--------------------------------------------------------${nl}${nl}"
    $email = @($subject,$body)
    Send-Mail -source $email -to "aphillips@cambridge.org"
    Exit
    }
}

## Compare-FileContent function
function Compare-FileContent  
{
    [CmdletBinding()]
    Param ($reffile, $tripwirefiles)
    ## Check reference and tripwire file content matches
    For ($i=0; $i -lt $tripwirefiles.Length; $i++) {
        $refcontent = Get-Content $reffile
        $tripfile = $tripwirefiles[$i]
	    $tripcontent = Get-Content $tripfile
	    if (Compare-Object $refcontent $tripcontent) {
		    ## files don't match
		    Write-Verbose "Compare-FileContent function failed, because the content of the reference file $reffile and the tripfile $tripfile don't match"
            $body2 = "${nl}${nl}Tripwire file is: $tripfile `
                      ${nl}Reference file is: $reffile `
                      ${nl}${nl}Please restart the ransomware-tripwire service on infra-admin.ad.cambridge.org after resolving this issue"
            $body = -join ($body1FileContent, $body2)
            Write-Output "$body `
                          ${nl}-------------------------------------------------------- `
                          ${nl}Exiting the Ransomware monitoring script for Groupshares `
                          ${nl}--------------------------------------------------------${nl}${nl}"
            $email = @($subject,$body)
            Send-Mail -source $email -to "aphillips@cambridge.org"
            Exit
	    }
        else {
            Write-Verbose "Compare-FileContent function has successfully run, the content of the reference file and tripwirefiles matched"
        }
    }
}

## Setup some email variables
$subject = "Ransomware Monitoring: Tripwire or reference file error encountered when starting monitoring script"
$body1FileAccess = "The reference or tripwire file could not be accessed when starting script as $env:username on $env:computername, aborting monitoring script `
                    ${nl}Please notify GHS via xMatters as without the monitoring script we won't know if a virus is encrypting the files in Groupshares"
$body1FileContent = "Noticed the contents of the reference and tripwire files do not match when starting script as $env:username on $env:computername, aborting monitoring script `
                     ${nl}Please notify GHS via xMatters as without the monitoring script we won't know if a virus is encrypting the files in Groupshares"

## Check all is well before we start continual monitoring
Check-FileAccess -reffile $reffileA -tripwirefiles $tripwireAfiles 
Check-FileAccess -reffile $reffileZ -tripwirefiles $tripwireZfiles

Compare-FileContent -reffile $reffileA -tripwirefiles $tripwireAfiles
Compare-FileContent -reffile $reffileZ -tripwirefiles $tripwireZfiles

Write-Verbose "Just before the main while loop, after doing initial checks"


## Start continual monitoring of tripwire files
while($True){
   	
    Write-Verbose "At the start of the main while loop"
    
    ## Setup some email variables
    $subject = "POTENTIAL VIRUS ENCRYPTING GROUPSHARES FILES -- a tripwire file has been modified, deleted or renamed"
    $body1FileAccess = "A tripwire file has been renamed or deleted `
                        ${nl}Please notify GHS via xMatters as the rename/delete could have been made by a ransomware virus that is encrypting our files"
    $body1FileContent = "A tripwire file has been modified `
                         ${nl}Please notify GHS via xMatters as the modification could have been made by a ransomware virus that is encrypting our files"
    
    Check-FileAccess -reffile $reffileA -tripwirefiles $tripwireAfiles 
    Check-FileAccess -reffile $reffileZ -tripwirefiles $tripwireZfiles

    Compare-FileContent -reffile $reffileA -tripwirefiles $tripwireAfiles
    Compare-FileContent -reffile $reffileZ -tripwirefiles $tripwireZfiles
            
    Write-Verbose "Looping after sleeping for 20 seconds"
    Start-Sleep -s 20

}
