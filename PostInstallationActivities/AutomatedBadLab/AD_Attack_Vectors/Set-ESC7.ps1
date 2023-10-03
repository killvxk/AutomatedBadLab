Function Set-ESC7 {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string[]]$VulnUsers
    )

    Write-Host "  [+] Providing a vulnerable user danagerous rights over the CA Object (ESC7)" -ForegroundColor Green

    # Get two random and distinct users from $VulnUsers
    $SelectedVulnUsers = ($VulnUsers | Get-Random -Count 2)

    # 1 = ManageCA || 2 = Issue Certificates
    $AccessMask = 1
    
    Foreach ($VulnUser in $SelectedVulnUsers) {

        # Get the ADUser Object
        $VulnUser = Get-ADUser -Identity $VulnUser

        If ($AccessMask -eq 1) {
            Write-Verbose "Providing $($VulnUser.SamAccountName) with ManageCA Rights"
        }
        Else {
            Write-Verbose "Providing $($VulnUser.SamAccountName) with Issue and Manage Certificate Rights"
        }

        # Get the CA Objects to modify
        $CAComputer = Get-ADComputer -Identity (Get-ADGroupMember -Identity "Cert Publishers" | Where-Object objectClass -EQ computer).name
        $CAName = (Get-ADObject -LDAPFilter "(ObjectClass=certificationAuthority)" -SearchBase "CN=Certification Authorities,CN=Public Key Services,CN=Services,CN=Configuration,$((Get-ADRootDSE).defaultNamingContext)").Name

        $Paths = @("Configuration\$($CAName)", "Security")

        Foreach ($Path in $Paths) {

            If ($Path -eq "Security") {
                $AccessMask = 48
            }

            # Registry Path
            $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\$Path"

            Invoke-Command -ComputerName $CAComputer.Name -ScriptBlock {
                param($VulnUser, $AccessMask, $RegPath)

                $ace = New-Object System.Security.AccessControl.CommonAce ([System.Security.AccessControl.AceFlags]::None, [System.Security.AccessControl.AceQualifier]::AccessAllowed, $AccessMask, $VulnUser.SID, $false, $null)

                # Build the new ACL
                $binaryData = Get-ItemProperty -Path $RegPath -Name "Security"
                $sd = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList $binaryData.Security, 0

                $sd.DiscretionaryAcl.InsertAce($sd.DiscretionaryAcl.Count, $ace)
                $sdBytes = New-Object byte[] $sd.BinaryLength
                $sd.GetBinaryForm($sdBytes, 0)

                # Append new ACL to Security REG_BINARY blob
                Set-ItemProperty -Path $RegPath -Name "Security" -Value $sdBytes
                
                # Restart ADCS for the perms to take
                Restart-Service -Name 'Certsvc'

            } -ArgumentList $VulnUser, $AccessMask, $RegPath
        }

        # Give second user ManageCertificate Rights
        $AccessMask = 2 
    }
}