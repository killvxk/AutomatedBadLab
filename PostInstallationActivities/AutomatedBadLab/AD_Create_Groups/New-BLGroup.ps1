Function New-BLGroup {

    # Creates new AD group with random attributes

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][int32]$GroupCount
    )

    Write-Host "[+] Creating $GroupCount AutomatedBadLab Groups.." -ForegroundColor Green

    # Currently only have 100 groups to choose from
    If ($GroupCount -gt 100) {
        $GroupCount = 100
    }

    # Create a loop to create the specified number of computer objects
    for ($CreatedGroups= 1; $CreatedGroups -le $GroupCount; $CreatedGroups++) {

        # Pick random OU to put the group in and a random user to be the owner
        $Owner = (Get-ADUser -Filter * | Get-Random).DistinguishedName
        $OUPath = (ADOrganizationalUnit -Filter * | Get-Random).DistinguishedName
        $Description = "Group generated by AutomatedBadLab"
        
        # Pick a random entry from Groups.txt to use as the group name
        $GroupName = Get-Content -Path (Join-Path $PSScriptRoot 'Groups.txt') | Get-Random

        # Track progress
        Write-Progress -Activity "Creating AD Groups" -Status "Creating Group $CreatedGroups of $GroupCount" `
        -CurrentOperation $GroupName -PercentComplete ($CreatedGroups / $GroupCount * 100)

        # If the group already exists, break out of the loop and try again
        If (Get-ADGroup -Filter { SamAccountName -eq $GroupName }) {
            Break
        }

        $AdminGroups = @("IT Support", "HR Staff", "Operations Team", "Development Squad", "Legal Department", "System Administration", "Engineering Group", "Compliance Department", "IT Security", "Technical Support")

        If ($GroupName -contains $adminGroups) {
            $GroupCategory = 'Security'
            $GroupScope = 'Global'
        }
        Else {
            $GroupCategory = 'Distribution'
            $GroupScope = 'Universal', 'DomainLocal' | Get-Random
        }

        # Create the group
        New-ADGroup -Name $GroupName -Description $Description -Path $OUPath -GroupCategory $GroupCategory -GroupScope $GroupScope -ManagedBy $Owner
    } 
}

Write-Progress -Activity "Created Group Objects.." -Completed