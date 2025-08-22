Configuration OSLab_OperatingSystem
{
    param
    (
        [string]$WallpaperPath = $null,
        [string]$DefaultAppAssociationsPath = $null,
        [boolean]$EnableAutoLogon = $false,
        [pscredential]$AutoLogonCredential,
        [boolean]$DisableEdgePasswordManager = $false,
        [string]$SplashScreenTaskPath = $null,
        [string]$AutoLoadClientTaskPath = $null,
        [string]$Culture = $null,
        [boolean]$EnsureSshServer = $false
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    if ($WallpaperPath) {
        Registry 'SetWallpaper'
        {
            Key          = 'HKCU:\Control Panel\Desktop'
            ValueName    = 'Wallpaper'
            ValueData    = $WallpaperPath
            ValueType    = 'String'
            Ensure       = 'Present'
        }
    }

    if ($DefaultAppAssociationsPath) {
        Script 'SetDefaultAppAssociations'
        {
            GetScript  = { @{ Result = '' } } # Cannot easily test this state
            SetScript  = { Dism.exe /Online /Import-DefaultAppAssociation:$using:DefaultAppAssociationsPath }
            TestScript = { return $false } # Always run
        }
    }

    if ($EnableAutoLogon) {
        Registry 'EnableAutoLogon'
        {
            Key       = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            ValueName = 'AutoAdminLogon'
            ValueData = '1'
            ValueType = 'String'
            Ensure    = 'Present'
        }
        Registry 'SetDefaultUserName'
        {
            Key       = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            ValueName = 'DefaultUserName'
            ValueData = $AutoLogonCredential.UserName
            ValueType = 'String'
            Ensure    = 'Present'
        }
        Registry 'SetDefaultPassword'
        {
            Key       = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            ValueName = 'DefaultPassword'
            ValueData = $AutoLogonCredential.GetNetworkCredential().Password
            ValueType = 'String'
            Ensure    = 'Present'
        }
    }

    if ($DisableEdgePasswordManager) {
        Registry 'DisableEdgePasswordManager'
        {
            Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
            ValueName = 'PasswordManagerEnabled'
            ValueData = 0
            ValueType = 'DWord'
            Ensure    = 'Present'
        }
    }

    if ($SplashScreenTaskPath) {
        ScheduledTask 'ShowLabSplashScreen'
        {
            TaskName   = 'ShowLabSplashScreen'
            Action     = New-ScheduledTaskAction -Execute $SplashScreenTaskPath
            Trigger    = New-ScheduledTaskTrigger -AtLogOn
            State      = 'Enabled'
            Ensure     = 'Present'
        }
    }

    if ($AutoLoadClientTaskPath) {
        ScheduledTask 'AutoLoadOSClient'
        {
            TaskName   = 'AutoLoadOSClient'
            Action     = New-ScheduledTaskAction -Execute $AutoLoadClientTaskPath
            Trigger    = New-ScheduledTaskTrigger -AtLogOn
            State      = 'Enabled'
            Ensure     = 'Present'
        }
    }

    if ($Culture) {
        Script 'SetSystemCulture'
        {
            GetScript  = { @{ Result = (Get-Culture).Name } }
            SetScript  = { Set-Culture $using:Culture }
            TestScript = { (Get-Culture).Name -eq $using:Culture }
        }
    }

    if ($EnsureSshServer) {
        WindowsCapability 'OpenSSHServer'
        {
            Name   = 'OpenSSH.Server~~~~0.0.1.0'
            Ensure = 'Present'
        }
    }
}
