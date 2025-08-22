Configuration OSLab_OneStreamAppServer
{
    param
    (
        [Parameter(Mandatory)] [string]$Version,
        [Parameter(Mandatory)] [string]$SourcePath,
        [Parameter(Mandatory)] [string]$InstallPath,
        [Parameter(Mandatory)] [string]$ConnectionString,
        [string]$LicenseKeyPath = $null,
        [hashtable]$AppSettings = $null,
        [hashtable]$GatewayConfig = $null,
        [string[]]$EnsureFolders = $null,
        [Parameter(Mandatory = $false)] [ValidateSet("Present", "Absent")] [string]$Ensure = "Present"
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    $InstallerArgs = "/s /v`"/qn INSTALLDIR=`"`"$InstallPath`"`"`""

    Script 'InstallOneStream'
    {
        GetScript = { @{ Result = (Test-Path -Path (Join-Path $InstallPath "OneStreamServer.exe")) } }
        SetScript = {
            . "$PSScriptRoot\\..\\..\\Private\\HelperFunctions.ps1"
            Install-OSSoftware -FilePath $using:SourcePath -Arguments $using:InstallerArgs
        }
        TestScript = { Test-Path -Path (Join-Path $InstallPath "OneStreamServer.exe") }
    }

    Script 'ConfigureOneStream'
    {
        GetScript = {
            $configPath = Join-Path $using:InstallPath "OneStreamServer.exe.config"
            $content = Get-Content $configPath
            $isConfigured = $content -like "*$($using:ConnectionString)*"
            @{ Result = $isConfigured }
        }
        SetScript = {
            $configPath = Join-Path $using:InstallPath "OneStreamServer.exe.config"
            $config = [xml](Get-Content $configPath)
            $config.configuration.appSettings.add | Where-Object { $_.key -eq "DbConnString" } | ForEach-Object { $_.value = $using:ConnectionString }
            $config.Save($configPath)
        }
        TestScript = {
            $configPath = Join-Path $using:InstallPath "OneStreamServer.exe.config"
            (Get-Content $configPath) -like "*$($using:ConnectionString)*"
        }
        DependsOn = '[Script]InstallOneStream'
    }
}
