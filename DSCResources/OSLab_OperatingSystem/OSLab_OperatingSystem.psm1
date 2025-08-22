Configuration OSLab_OperatingSystem
{
    param
    (
        [string]$WallpaperPath,
        [string]$DefaultAppAssociationsPath,
        [boolean]$EnableAutoLogon,
        [pscredential]$AutoLogonCredential,
        [boolean]$DisableEdgePasswordManager,
        [string]$SplashScreenTaskPath,
        [string]$AutoLoadClientTaskPath
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
            ActionPath = $SplashScreenTaskPath
            Trigger    = 'AtLogOn'
            State      = 'Enabled'
        }
    }

    if ($AutoLoadClientTaskPath) {
        ScheduledTask 'AutoLoadOSClient'
        {
            TaskName   = 'AutoLoadOSClient'
            ActionPath = $AutoLoadClientTaskPath
            Trigger    = 'AtLogOn'
            State      = 'Enabled'
        }
    }
}
