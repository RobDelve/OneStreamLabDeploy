Configuration OSLab_DotNetHostingBundle
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    $InstallerArgs = "/install /quiet /norestart"
    $RegistryPath = "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

    Script "InstallDotNetHostingBundle"
    {
        GetScript = {
            $installed = Get-ChildItem -Path $RegistryPath | Get-ItemProperty | Where-Object { $_.DisplayName -match "Microsoft .NET Hosting Bundle" -and $_.DisplayVersion -eq $using:Version }
            @{ Result = [bool]$installed }
        }
        SetScript = {
            . "$PSScriptRoot\\..\\..\\Private\\HelperFunctions.ps1"
            if ($using:Ensure -eq 'Present') {
                Install-OSSoftware -FilePath $using:SourcePath -Arguments $using:InstallerArgs
            }
            # Note: A proper 'Absent' implementation would require finding the product code and running msiexec /x
        }
        TestScript = {
            $installed = Get-ChildItem -Path $RegistryPath | Get-ItemProperty | Where-Object { $_.DisplayName -match "Microsoft .NET Hosting Bundle" -and $_.DisplayVersion -eq $using:Version }
            return [bool]$installed
        }
    }
}
