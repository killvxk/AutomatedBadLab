# https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-scenarios-windows-server-active-directory

Function Install-LAPS {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string[]]$VulnUsers
    )

    Write-Host "  [+] Installing LAPS" -ForegroundColor Green

    # Pick a real non-DC object to install LAPS on
    $DCDistinguishedName = (Get-ADDomainController).ComputerObjectDN

    $LAPSComputer = Get-ADComputer -Filter * -Properties Description |`
    Where-Object { ($_.Description -notlike '*AutomatedBadLab*') -and ($_.DistinguishedName -ne $DCDistinguishedName) } |`
    Get-Random -Count 1

    # Check we have a computer object to install LAPS on
    if ($null -eq $LAPSComputer) {
        Write-Host "  [!] No computer found to install LAPS on" -ForegroundColor Red
        return
    }

    # Update Schema before introducing LAPS to the AD
    Update-LapsADSchema -Confirm:$False

    # Variables
    $LapsOUName = "LAPS Computers"
    $LapsGPOName = "LAPS Policy GPO"

    # Create the OU the LAPS managed computers will reside in 
    New-ADOrganizationalUnit -Name $LapsOUName -Description "Computer Objects managed by LAPS" -ErrorAction SilentlyContinue

    # LAPS OU object to link LAPS GPO to
    $LapsOU = Get-ADOrganizationalUnit -Filter "Name -eq '$LapsOUName'"

    # Grant permission to the OU to update passwords
    Set-LapsADComputerSelfPermission -Identity $LapsOU

    # Make the computer object subject to LAPS policies
    Move-ADObject -Identity $LAPSComputer.DistinguishedName -TargetPath $LapsOU
    Write-Host "    [+] Moved $($LAPSComputer.DistinguishedName) into $($LapsOU.DistinguishedName)" -ForegroundColor Yellow

    # Pick a random vulnerable user to give LAPS Extended Rights
    $VulnUser = $VulnUsers | Get-Random
    Set-LapsADReadPasswordPermission -Identity $LapsOU -AllowedPrincipals "$((Get-ADDomain).Forest)\$VulnUser"

    Write-Host "    [+] Provided $VulnUser permission to read $($LAPSComputer.SamAccountName) LAPS password" -ForegroundColor Yellow

    # --------------------------------------------------------------------------------------------
    # Create the GPO with the LAPS Policy registry keys
    $GPODescription = "GPO generated by AutomatedBadLab"
    New-GPO -Name $LapsGPOName -Comment $GPODescription | New-GPLink -Target $LapsOU -Enforced Yes

    # Define the registry keys to set - https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-management-policy-settings#apply-policy-settings
    $RegKeys = @{
        "BackupDirectory" = 2
        "PasswordAgeDays" = 1
        "PasswordLength" = 24
        "PasswordComplexity" = 4
        "PasswordExpirationProtectionEnabled" = 1
        "ADPasswordEncryptionEnabled" = 1
        "ADPasswordEncryptionPrincipal" = "$((Get-ADDomain).Forest)\$VulnUser"
        "ADEncryptedPasswordHistorySize" = 12
        "ADBackupDSRMPassword" = 1
        "PostAuthenticationResetDelay" = 12
        "PostAuthenticationActions" = 3
    }

    # Set the registry keys in the GPO and on the local machine DC
    foreach ($key in $RegKeys.Keys) {
        if ($key -eq "ADPasswordEncryptionPrincipal") {
            Set-GPRegistryValue -Name $LapsGPOName -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\Config" -ValueName $key -Type String -Value $RegKeys[$key]
        }
        Else {
            Set-GPRegistryValue -Name $LapsGPOName -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\Config" -ValueName $key -Type DWord -Value $RegKeys[$key]
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\Config" -Name $key -Value $RegKeys[$key]
    }

    # Update the GPO on the computer or user
    Invoke-GPUpdate -Computer $LAPSComputer.DNSHostName -RandomDelayInMinutes 0 -Force -Target Computer

    # Configure Auditing to see what this looks like when abused
    Set-LapsADAuditing -Identity $LapsOU -AuditedPrincipals "$((Get-ADDomain).Forest)\$VulnUser" -AuditType Success,Failure

    # Invoke LAPS Policy Processing after our changes
    Invoke-LapsPolicyProcessing
}
