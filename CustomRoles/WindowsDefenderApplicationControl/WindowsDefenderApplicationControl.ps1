Param (
    [Parameter(Mandatory = $True)]
    [ValidateSet("Allow", "Deny")]
    [string]$Action,

    [Parameter(Mandatory = $False)]
    [bool]$DCS
)

$LogFilePath = "C:\WDACInstall.log"

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[+] $Timestamp - $Message"
    $LogMessage | Out-File -FilePath $LogFilePath -Append
}

Write-Log -Message "Installing Windows Defender Application Control.."

# Grab Example CI as template
$WDACPolicyPath = $env:windir + "\System32\CodeIntegrity\CIPolicies\Active"

If ($Action -eq "Allow") {
    $ExamplePolicyXML = "C:\Windows\schemas\CodeIntegrity\ExamplePolicies\DefaultWindows_Audit.xml"
    If ($DCS) {
        $WDACPolicyName = "AutomatedBadLab_Audit_DCS_Allow.xml"
        Write-Log -Message "Creating new WDAC Policy in Allow mode with Auditing plus Dynamic Code Security"
    }
    Else {
        $WDACPolicyName = "AutomatedBadLab_Audit_Allow.xml"
        Write-Log -Message "Creating new WDAC Policy in Allow mode with Auditing"
    }
} Else {
    $ExamplePolicyXML = "C:\Windows\schemas\CodeIntegrity\ExamplePolicies\DenyAllAudit.xml"
    If ($DCS) {
        $WDACPolicyName = "AutomatedBadLab_Audit_DCS_Deny.xml"
        Write-Log -Message "Creating new WDAC Policy in Deny mode with Auditing plus Dynamic Code Security"
    }
    Else {
        $WDACPolicyName = "AutomatedBadLab_Audit_Deny.xml"
        Write-Log -Message "Creating new WDAC Policy in Deny mode with Auditing"
    }
}

# Create new WDAC Policy based off example schema
$WDACPolicyFilePath = Join-Path $WDACPolicyPath $WDACPolicyName
Copy-Item $ExamplePolicyXML $WDACPolicyFilePath | Out-Null

# Reset identifiers to ours
Set-CIPolicyIdInfo -FilePath $WDACPolicyFilePath -PolicyName $WDACPolicyName -ResetPolicyID | Out-Null
Set-CIPolicyVersion -FilePath $WDACPolicyFilePath -Version "1.0.0.0" | Out-Null

If ($DCS) {
    # Add Dynamic Code Security to the policy
    Set-RuleOption -FilePath $WDACPolicyFilePath -Option 19 | Out-Null
}

# Permit Windows and Program Files directories
$PathRules += New-CIPolicyRule -FilePathRule "%windir%\*" | Out-Null
$PathRules += New-CIPolicyRule -FilePathRule "%OSDrive%\Program Files\*" | Out-Null
$PathRules += New-CIPolicyRule -FilePathRule "%OSDrive%\Program Files (x86)\*" | Out-Null
Merge-CIPolicy -OutputFilePath $WDACPolicyFilePath -PolicyPaths $WDACPolicyFilePath -Rules $PathRules | Out-Null

# Output new policy to XML
[xml]$WDACPolicyXML = Get-Content $WDACPolicyFilePath
$WDACPolicyBinaryFileName = "$($WDACPolicyXML.SiPolicy.PolicyID).cip"
$WDACPolicyBinary = Join-Path $WDACPolicyPath $WDACPolicyBinaryFileName

# Convert to binary policy
ConvertFrom-CIPolicy $WDACPolicyFilePath $WDACPolicyBinary | Out-Null

# Distribute as GPO if executed on DC
If (Get-Module -ListAvailable -Name GroupPolicy) {

    Write-Log -Message "WDAC Policy installed on a Domain Controller, distributing via GPO"

    $WDACPolicySMBPath = "\\$((Get-ADDomain).DNSRoot)\SYSVOL\$((Get-ADDomain).DNSRoot)\Scripts\$WDACPolicyBinaryFileName"

    # Save Policy to SYSVOL to distrubute via GPO
    Copy-Item $WDACPolicyBinary -Destination $WDACPolicySMBPath | Out-Null

    # Create WDAC GPO
    $WDACGPOName = "WDAC DCS GPO"
    $GPODescription = "GPO generated by AutomatedBadLab"

    New-GPO -Name $WDACGPOName -Comment $GPODescription | Out-Null

    # Enable Code Integrity
    $EnableParams = @{
        Name      = $WDACGPOName
        Key       = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard'
        Type      = 'Dword'
        ValueName = 'DeployConfigCIPolicy'
        Value     = 1
    }
    Set-GPRegistryValue @EnableParams | Out-Null

    # Set Policy Path
    $PolicyPathParams = @{
        Name      = $WDACGPOName
        Key       = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard'
        Type      = 'String'
        ValueName = 'ConfigCIPolicyFilePath'
        Value     = $WDACPolicySMBPath
    }
    Set-GPRegistryValue @PolicyPathParams | Out-Null

    # Link the GPO to set it Domain wide
    $DomainDN = (Get-ADDomain).DistinguishedName
    New-GPLink -Name $WDACGPOName -Target $DomainDN -LinkEnabled Yes -Enforced Yes | Out-Null

    # Force an immediate group policy update to apply
    Invoke-GPUpdate -RandomDelayInMinutes 0 -Force | Out-Null

    Write-Log -Message "Perform gpupdate and reboot on other domain joined machines to complete WDAC install"
}
Else {
    $CiToolPath = "C:\Windows\System32\CiTool.exe"
    If (Test-Path $CiToolPath) {
        $CiToolArgs = "--update-policy `"$WDACPolicyBinary`" "
        Start-Process -FilePath $CiToolPath -ArgumentList $CiToolArgs
        Write-Log -Message "Installed WDAC Policy using CiTool.exe"
    }
    Else {
        $WDACPolicyToolURL = "https://download.microsoft.com/download/2/d/5/2d598537-6131-40ba-a1e3-f664b97fef6e/RefreshCIPolicy/AMD64/RefreshPolicy(AMD64).exe"
        $WDACPolicyTool = $WDACPolicyPath + "\RefreshPolicy.exe"
        Invoke-WebRequest -Uri $WDACPolicyToolURL -OutFile $WDACPolicyTool
        Start-Process -FilePath $WDACPolicyTool -Wait
        Write-Log -Message "Installed WDAC Policy using WDAC Refresh Policy Tool"
    }
}