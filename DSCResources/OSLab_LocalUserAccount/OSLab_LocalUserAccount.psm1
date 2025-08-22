Configuration OSLab_LocalUserAccount
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter()]
        [pscredential]$Password,

        [Parameter()]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Script "ManageUser_$($UserName)"
    {
        GetScript = {
            $exists = Get-LocalUser -Name $using:UserName -ErrorAction SilentlyContinue
            @{ Result = [bool]$exists }
        }
        SetScript = {
            if ($using:Ensure -eq 'Present') {
                $user = New-LocalUser -Name $using:UserName -Password $using:Password -FullName $using:UserName -Description "Managed by DSC"
                if ($using:NewName) {
                    $user | Rename-LocalUser -NewName $using:NewName
                }
            } else {
                Remove-LocalUser -Name $using:UserName
            }
        }
        TestScript = {
            $userToTest = if ($using:NewName) { $using:NewName } else { $using:UserName }
            $exists = Get-LocalUser -Name $userToTest -ErrorAction SilentlyContinue
            return [bool]$exists
        }
    }
}
