﻿Function New-Pre2KComputerAccount {

    [CmdletBinding()] # Required for -Verbose flag to work
    param ()

    Write-Host "  [+] Creating a Pre 2k Computer Account" -ForegroundColor Green

    # Common variables
    $Owner = (Get-ADUser -Filter * | Get-Random).DistinguishedName

    # Generate a random computer name
    $Prefixes = @("APP", "WEB", "MAIL", "FILE", "DNS", "DC", "DHCP", "WINS", "SQL", "VPN", "PROXY", "NTP") 
    $Name = "$($Prefixes | Get-Random)-$([guid]::NewGuid().ToString().Substring(0, 8).ToUpper())"

    # Create the computer object using net computer which wil create it as a pre-2K object
    net computer "\\$Name" /add 

    # Create the computer object with random attributes
    Get-ADComputer $Name | Set-ADComputer `
        -SAMAccountName $Name `
        -DNSHostName "$Name.$((Get-AdDomain).Forest)" `
        -Enabled $True `
        -Description "Computer generated by AutomatedBadLab before Y2K" `
        -Location "Building $(Get-Random -Minimum 1 -Maximum 10), Floor $(Get-Random -Minimum 1 -Maximum 5)" `
        -ManagedBy $Owner `
        -OperatingSystem "Windows $('NT', '95', '98' | Get-Random)" `
        -OperatingSystemVersion "$(Get-Random -Minimum 1 -Maximum 3).0.$(Get-Random -Minimum 10000 -Maximum 12000)" `
        -OperatingSystemServicePack "Service Pack $(Get-Random -Minimum 0 -Maximum 3)"

    # Doesn't seem to create it with the PASSWD_NOTREQD flag set so set it manually
    Get-ADComputer $Name | Set-ADAccountControl -PasswordNotRequired $True

    Write-Verbose "$Name computer created with the password $($Name.ToLower())"
}
