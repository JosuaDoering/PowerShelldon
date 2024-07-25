Import-Module PersonalManagement
Import-Module ActiveDirectory
Import-Module New-Password

# Initialize Data
$PmCredentials = Get-AutomationPSCredential -Name 'SU_PersonalManagement'
$AdCredentials = Get-AutomationPSCredential -Name 'SU_ActiveDirectory'
$AdOU = 'OU=UserAccounts,DC=TESTDOMAIN,DC=COM'
$ReportMailRecipients = @('infrastructure@testdomain.com')
$Log = ""

#################################################
################### Get Users ###################
#################################################

Connect-PMService -Credential $PmCredentials
$pmUsers = Get-PMUser
"PersonalManagement: $($usersFromPM.Count) users found" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }

$adUsers = Get-ADUser -Filter * -SearchBase $AdOU -Properties Mail, AccountExpirationDate, Manager, DisplayName, Department, Title
"AD: $($adUsers.Count) users found" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }

foreach ($pmUser in $pmUsers) {
    $adUser = $adUsers | Where-Object Mail -eq $pmUser.Email

    if (-not $adUser) {
        #################################################
        ################### Onboarding ##################
        #################################################

        ## Create user
        $adManager = $adUsers | Where-Object Mail -eq $pmUser.Supervisor -Properties Mail
        $samAccountName = ($pmUser.FirstName.Substring(0, 1) + $pmUser.LastName).ToLower()
        $createUserSplat = [ordered]@{
            Credential     = $AdCredentials
            Path           = $AdOU
            Name           = "$($pmUser.FirstName) $($pmUser.LastName)"
            DisplayName    = "$($pmUser.FirstName) $($pmUser.LastName)"
            GivenName      = $pmUser.FirstName
            Surname        = $pmUser.LastName
            SamAccountName = $samAccountName # First letter of first name and lastname, lowercase
            Title          = $pmUser.JobTitle
            Company        = 'Test Company GmbH'
            OfficePhone    = $pmUser.PhoneNumber
            Manager        = $adManager.DistinguishedName
            Department     = $pmUser.Department
        }
        $null = New-ADUser @createUserSplat
        "$($pmUser.Email): AD user created" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }

        ## Set password and activate user
        $password = New-Password
        Set-ADAccountPassword -Identity $samAccountName -NewPassword ($password | ConvertTo-SecureString -AsPlainText -Force) -Reset -Credential $AdCredentials
        Set-ADUser -Identity $samAccountName -Enabled $true -ChangePasswordAtLogon $true -Server $AdServer -Credential $AdCredentials
        "$($pmUser.Email): AD user activated" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }

        if ($pmUser.TerminationDate) {
            Set-ADAccountExpiration -Identity $samAccountName -DateTime $pmUser.TerminationDate -Credential $AdCredentials
        }

        ## Send password to manager
        $sendMailSplat = @{
            To         = $Recipient
            Subject    = $Subject
            Body       = "New user: $samAccountName`n Password: $password"
            From       = 'automation@testdomain.com'
            SmtpServer = 'smtp01.testdomain.com'
            Encoding   = 'utf8'
        }
        $null = Send-MailMessage @sendMailSplat
        Clear-Variable sendMailSplat
        "$($pmUser.Email): Password sent to manager" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
    }
    else {
        #################################################
        #################### Change #####################
        #################################################

        ## Email
        if ($adUser.Mail -ne $pmUser.Email) {
            Set-ADUser -Identity $adUser.SamAccountName -Credential $AdCredentials -Mail $pmUser.Email
            "$($pmUser.Email): Email address changed from '$($adUser.Mail)' to '$($pmUser.Email)'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }

        ## Name Change
        $nameChange = $false
        ### First Name
        if ($adUser.givenName -ne $pmUser.FirstName) {
            $nameChange = $true
            Set-ADUser -Identity $adUser.SamAccountName -Credential $AdCredentials -GivenName $pmUser.FirstName
            "$($pmUser.Email): First name changed from '$($adUser.givenName)' to '$($pmUser.FirstName)'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }
        ### Last Name
        if ($adUser.surname -ne $pmUser.LastName) {
            $nameChange = $true
            Set-ADUser -Identity $adUser.SamAccountName -Credential $AdCredentials -Surname $pmUser.LastName
            "$($pmUser.Email): Last name changed from '$($adUser.surname)' to '$($pmUser.LastName)'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }
        if ($nameChange -eq $true) {
            $name = "$($pmUser.FirstName) $($pmUser.LastName)"
            Set-ADUser -Identity $samAccountName -DisplayName $displayName -Credential $AdCredentials
            "$($pmUser.Email): DisplayName changed from '$($adUser.DisplayName)' to '$name'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
            Rename-ADObject -Identity $samAccountName -NewName $displayName -Credential $AdCredentials
            "$($pmUser.Email): Name changed from '$($adUser.Name)' to '$name'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }

        ## Department
        if ($adUser.department -ne $pmUser.Department) {
            Set-ADUser -Identity $adUser.SamAccountName -Replace @{ Department = $pmUser.Department } -Credential $AdCredentials
            "$($pmUser.Email): Department changed from '$($adUser.department)' to '$($pmUser.Department)'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }

        ## Job Title
        if ($adUser.Title -ne $pmUser.Department) {
            Set-ADUser -Identity $adUser.SamAccountName -Replace @{ Title = $pmUser.JobTitle } -Credential $AdCredentials
            "$($pmUser.Email): Job Title changed from '$($adUser.Title)' to '$($pmUser.JobTitle)'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }

        ## Manager
        $adManager = $adUsers | Where-Object Mail -eq $pmUser.Supervisor -Properties Mail
        if ($adUser.Manager -ne $adManager.DistinguishedName) {
            Set-ADUser -Identity $adUser.SamAccountName -Manager $adManager.DistinguishedName -Credential $AdCredentials
            "$($pmUser.Email): Manager changed from '$($adUser.Manager)' to '$($adManager.DistinguishedName)'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }

        ## Account Expiration Date
        if ($adUser.AccountExpirationDate -ne $pmUser.TerminationDate) {
            $adUser | Set-ADAccountExpiration -Identity $adUser.SamAccountName -DateTime $pmUser.TerminationDate -Credential $AdCredentials
            "$($pmUser.Email): Manager changed from '$($adUser.AccountExpirationDate)' to '$($pmUser.TerminationDate)'" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
        }
    }
}

#################################################
################## Offboarding ##################
#################################################

$adUsersToRemove = $adUsers | Where-Object AccountExpirationDate -ge (Get-Date)

foreach ($adUser in $adUsersToRemove) {
    # Change password
    Set-ADAccountPassword -Identity $adUser.SamAccountName -NewPassword (New-Password | ConvertTo-SecureString -AsPlainText -Force) -Reset -Credential $AdCredentials
    Set-ADUser -Identity $adUser.SamAccountName -Enabled $false -Credential $AdCredentials
    "$($adUser.Mail): Termination date reached ($($adUser.AccountExpirationDate)) -> Disabled AD user" | ForEach-Object { $Log += "`n$PSItem"; Write-Output $PSItem }
}

#################################################
################ Send Report Mail ###############
#################################################

$sendMailSplat = @{
    To         = $ReportMailRecipients
    Subject    = 'REPORT - PersonalManagement_AD_Sync'
    Body       = $Log
    From       = 'automation@testdomain.com'
    SmtpServer = 'smtp01.testdomain.com'
    Encoding   = 'utf8'
}
$null = Send-MailMessage @sendMailSplat
Write-Output "Report mail sent to $($ReportMailRecipients -join ', ')"