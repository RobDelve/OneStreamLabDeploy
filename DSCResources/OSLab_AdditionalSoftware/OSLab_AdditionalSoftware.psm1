Configuration OSLab_AdditionalSoftware
{
    param
    (
        [string[]]$PackageNames
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ChocolateyManagementDsc'

    # Ensure Chocolatey is installed
    Chocolatey 'InstallChocolatey'
    {
        Ensure = 'Present'
    }

    # Install the specified packages
    foreach ($packageName in $PackageNames)
    {
        cChocoPackageInstaller $packageName
        {
            Name      = $packageName
            Ensure    = 'Present'
            DependsOn = '[Chocolatey]InstallChocolatey'
        }
    }
}
