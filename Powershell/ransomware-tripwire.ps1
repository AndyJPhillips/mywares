## Setup a variable to represent newline
$nl = "`r`n"

Write-Host "----------------------------------------------------- `
            ${nl}Starting Ransomware monitoring script for Groupshares `
            ${nl}-----------------------------------------------------"

$ErrorActionPreference = "Stop"

## Check to see if J drive exists, if not map it to the groupshares DFS address
Write-Host "${nl}Mounting the J drive for scanning${nl}"
If (!(Test-Path J:)) {
    New-PSDrive -Name J -PSProvider FileSystem –Root "\\server\path"
}
Write-Host "${nl}"

## Setup the various tripwire and reference files 
$tripfileA1 = "J:\Path1\a-dont-modify.docx"
$tripfileA2 = "J:\Path2\Staff Folders\a-dont-modify.docx"
$tripfileA3 = "J:\Path3\a-dont-modify.docx"
$tripfileA4 = "J:\Path4\a-dont-modify.docx"
$tripfileA5 = "J:\Path5\a-dont-modify.docx"
$tripfileA6 = "J:\Path6\a-dont-modify.docx"
$tripfileA7 = "J:\Path7\a-dont-modify.docx"
$tripfileA8 = "J:\Path8\a-dont-modify.docx"
$tripfileA9 = "J:\Path9\a-dont-modify.docx"
$tripfileA10 = "J:\Path10\a-dont-modify.docx"
$tripwireAfiles = @($tripfileA1,$tripfileA2,$tripfileA3,$tripfileA4,$tripfileA5,$tripfileA6,$tripfileA7,$tripfileA8,$tripfileA9,$tripfileA10)

$tripfileZ1 = "J:\Path1\z-dont-modify.docx"
$tripfileZ2 = "J:\Path2\Staff Folders\z-dont-modify.docx"
$tripfileZ3 = "J:\Path3\z-dont-modify.docx"
$tripfileZ4 = "J:\Path4\z-dont-modify.docx"
$tripfileZ5 = "J:\Path5\z-dont-modify.docx"
$tripfileZ6 = "J:\Path6\z-dont-modify.docx"
$tripfileZ7 = "J:\Path7\z-dont-modify.docx"
$tripfileZ8 = "J:\Path8\z-dont-modify.docx"
$tripfileZ9 = "J:\Path9\z-dont-modify.docx"
$tripfileZ10 = "J:\Path10\z-dont-modify.docx"
$tripwireZfiles = @($tripfileZ1,$tripfileZ2,$tripfileZ3,$tripfileZ4,$tripfileZ5,$tripfileZ6,$tripfileZ7,$tripfileZ8,$tripfileZ9,$tripfileZ10)

$reffileA = "J:\Computer Dept\Infrastructure Team\Ransomware-traps\Reference\a-dont-modify.docx"
$reffileZ = "J:\Computer Dept\Infrastructure Team\Ransomware-traps\Reference\z-dont-modify.docx"

## SEND MAIL FUNCTION
function sendMail($s, $to) {
    $smtpServer = "hostname-of-server.domain"
    $smtpFrom = "virus-monitor-donotreply@domain"
    $smtpTo = $to

    $messageSubject = $s[0]
    $message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
    $message.Subject = $messageSubject
    $message.IsBodyHTML = $false
    $message.Body = $s[1]

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($message)
}

## Check access to the reference & tripwire A files, before starting proper monitoring
try {
	$refcontentA = Get-Content $reffileA
    For ($i=0; $i -lt $tripwireAfiles.Length; $i++) {
		$tripfileA = $tripwireAfiles[$i]
		$tripcontentA = Get-Content $tripfileA
	}	
}

catch
    {
    ## Probably a file not found error, remember only tripwire files are writable
    $subject = "Tripwire file error encountered when starting monitoring script"
    $body = "The reference or tripwire file could not be found when starting script as $env:username on $env:computername, aborting monitoring script `
            ${nl}Please notify (someone) as without the monitoring script we won't know if a virus is encrypting the files in Groupshares `
            ${nl}${nl}Tripwire file is: $tripfileA `
            ${nl}Reference file is: $reffileA `
            ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
    Write-Host "$body `
                ${nl}-------------------------------------------------------- `
                ${nl}Exiting the Ransomware monitoring script for Groupshares `
                ${nl}--------------------------------------------------------${nl}${nl}"
    $email = @($subject,$body)
    sendMail -s $email -to "servicedesk@domain"
    Exit
}

## Check access to reference & tripwire Z files, before starting proper monitoring
try {
	$refcontentZ = Get-Content $reffileZ
    For ($i=0; $i -lt $tripwireZfiles.Length; $i++) {
		$tripfileZ = $tripwireZfiles[$i]
		$tripcontentZ = Get-Content $tripfileZ
	}	
}

catch
    {
    ## Probably a file not found error, remember only tripwire files are writable
    $subject = "Tripwire file error encountered when starting monitoring script"
    $body = "The reference or tripwire file could not be found when starting script as $env:username on $env:computername, aborting monitoring script `
            ${nl}Please notify (someone) as without the monitoring script we won't know if a virus is encrypting the files in Groupshares `
            ${nl}${nl}Tripwire file is: $tripfileZ `
            ${nl}Reference file is: $reffileZ `
            ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
     Write-Host "$body `
                 ${nl}-------------------------------------------------------- `
                 ${nl}Exiting the Ransomware monitoring script for Groupshares `
                 ${nl}--------------------------------------------------------${nl}${nl}"
    $email = @($subject,$body)
    sendMail -s $email -to "servicedesk@domain"
    Exit
}

## Check reference and tripwire (A files) content matches, before starting proper monitoring
For ($i=0; $i -lt $tripwireAfiles.Length; $i++) {
    $refcontentA = Get-Content $reffileA
    $tripfileA = $tripwireAfiles[$i]
	$tripcontentA = Get-Content $tripfileA
	if (Compare-Object $refcontentA $tripcontentA) {
		## files don't match
		$subject = "Tripwire file error encountered when starting monitoring script"
        $body = "Noticed the contents of the reference and tripwire files do not match when starting script as $env:username on $env:computername, aborting monitoring script `
                ${nl}Please notify (someone) as without the monitoring script we won't know if a virus is encrypting the files in Groupshares `
                ${nl}${nl}Tripwire file is: $tripfileA `
                ${nl}Reference file is: $reffileA `
                ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
        Write-Host "$body `
                    ${nl}-------------------------------------------------------- `
                    ${nl}Exiting the Ransomware monitoring script for Groupshares `
                    ${nl}--------------------------------------------------------${nl}${nl}"
		$email = @($subject,$body)
		sendMail -s $email -to "servicedesk@cambridge.org"
		Exit
	}
}
#Write-Host "Just before the main while loop, after leaving A for loop, `$body is set to: $body"

## Check reference and tripwire (Z files) content matches, before starting proper monitoring
For ($i=0; $i -lt $tripwireZfiles.Length; $i++) {
    $refcontentZ = Get-Content $reffileZ
    $tripfileZ = $tripwireZfiles[$i]
	$tripcontentZ = Get-Content $tripfileZ
	if (Compare-Object $refcontentZ $tripcontentZ) {
		## files don't match
		$subject = "Tripwire file error encountered when starting monitoring script"
        $body = "Noticed the contents of the reference and tripwire files do not match when starting script as $env:username on $env:computername, aborting monitoring script `
                ${nl}Please notify (someone) as without the monitoring script we won't know if a virus is encrypting the files in Groupshares `
                ${nl}${nl}Tripwire file is: $tripfileZ `
                ${nl}Reference file is: $reffileZ `
                ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
        Write-Host "$body `
                    ${nl}-------------------------------------------------------- `
                    ${nl}Exiting the Ransomware monitoring script for Groupshares `
                    ${nl}--------------------------------------------------------${nl}${nl}"
		$email = @($subject,$body)
		sendMail -s $email -to "servicedesk@cambridge.org"
		Exit
	}
}
#Write-Host "Just before the main while loop, after leaving Z for loop, `$body is set to: $body"

## Execute Watcher
while($TRUE){
   	
    #Write-Host "At the start of the main while loop"
    
    try {
        $refcontentA = Get-Content $reffileA
		For ($i=0; $i -lt $tripwireAfiles.Length; $i++) {
			$tripfileA = $tripwireAfiles[$i]
			$tripcontentA = Get-Content $tripfileA
			if (Compare-Object $refcontentA $tripcontentA) {
                ## files don't match
           	    $body = "A tripwire file has been modified `
                        ${nl}Please notify (someone) as the modification could have been made by a ransomware virus that is encrypting our files `
                        ${nl}${nl}Tripwire file is: $tripfileA `
                        ${nl}Reference file is: $reffileA `
                        ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
                Write-Host "$body"
                break
			}
		}
	}
    
    catch {
		## tripwire file deleted or renamed, as reference is read-only
		$body = "A tripwire file has been renamed or deleted `
                ${nl}Please notify (someone) as the rename/delete could have been made by a ransomware virus that is encrypting our files
                ${nl}${nl}Tripwire file is: $tripfileA `
                ${nl}Reference file is: $reffileA `
                ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
        Write-Host "$body"
	}
    
     try {
        $refcontentZ = Get-Content $reffileZ
		For ($i=0; $i -lt $tripwireZfiles.Length; $i++) {
			$tripfileZ = $tripwireZfiles[$i]
			$tripcontentZ = Get-Content $tripfileZ
			if (Compare-Object $refcontentZ $tripcontentZ) {
            ## files don't match
            $body = "A tripwire file has been modified `
                    ${nl}Please notify (someone) as the modification could have been made by a ransomware virus that is encrypting our files
                    ${nl}${nl}Tripwire file is: $tripfileZ `
                    ${nl}Reference file is: $reffileZ `
                    ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
            Write-Host "$body"
            break
			}
		}
	}
    
    catch {
		## tripwire file deleted or renamed, as reference is read-only
		$body = "A tripwire file has been renamed or deleted `
                ${nl}Please notify (someone) as the rename/delete could have been made by a ransomware virus that is encrypting our files
                ${nl}${nl}Tripwire file is: $tripfileZ `
                ${nl}Reference file is: $reffileZ `
                ${nl}${nl}Please restart the ransomware-tripwire service on (a server) after resolving this issue"
        Write-Host "$body"
	}
    

    #Write-Host "Just before the if statement that checks if `$body is set, the value of `$body is: $body"
	if ($body -ne $null) {
        $subject = "POTENTIAL VIRUS ENCRYPTING GROUPSHARES FILES -- a tripwire file has been modified, deleted or renamed"
		$email =@($subject,$body)
		sendMail -s $email -to "servicedesk@domain"
        Write-Host "$body `
                    ${nl}-------------------------------------------------------- `
                    ${nl}Exiting the Ransomware monitoring script for Groupshares `
                    ${nl}--------------------------------------------------------${nl}${nl}"
		## for additional recipients, just add more: 
		## sendMail -s $email -to "someuserorgroup@domain"
        Exit
	}
    
    # Write-Host "Looping after sleeping for 20 seconds"
    Start-Sleep -s 20

}