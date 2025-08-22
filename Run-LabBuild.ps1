# Run-LabBuild.ps1 - Example execution script for the test VM

# Import the module
Import-Module OneStreamLabDeploy -Force

# Load the configuration from the JSON file
$configPath = 'C:\Path\To\Your\OneStreamLabConfig.json'
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Prepare credentials (DSC requires PSCredential objects)
# In a real-world scenario, these would be retrieved securely (e.g., from Azure Key Vault)
$SqlSvcCred = Get-Credential -UserName '.\sqlservice' -Message 'Enter SQL Service Account Password'
$SqlNativeCred = Get-Credential -UserName $config.SqlServer.NativeUser -Message 'Enter SQL Native User Password'
$ServiceAcctCred = Get-Credential -UserName ".\$($config.WindowsAccounts.ServiceAccount.Name)" -Message 'Enter Service Account Password'
$DevAcctCred = Get-Credential -UserName ".\$($config.WindowsAccounts.DeveloperAccount.NewName)" -Message 'Enter Developer Account Password'

# Call the main build function with all parameters splatted from the config file
$buildParams = @{
    OneStreamVersion               = $config.OneStream.Version
    OneStreamSourcePath            = $config.OneStream.SourcePath
    OneStreamInstallPath           = $config.OneStream.InstallPath
    OneStreamLicenseKeyPath        = $config.OneStream.LicenseKeyPath
    OneStreamAppSettings           = $config.OneStream.AppSettings
    OneStreamGatewayConfig         = $config.OneStream.GatewayConfig
    OneStreamEnsureFolders         = $config.OneStream.EnsureFolders
    IdentityServerZipSourcePath    = $config.IdentityServer.ZipSourcePath
    IdentityServerInstallPath      = $config.IdentityServer.InstallPath
    IdentityServerAppPoolName      = $config.IdentityServer.AppPoolName
    IdentityServerHttpPort         = $config.IdentityServer.HttpPort
    IdentityServerHttpsPort        = $config.IdentityServer.HttpsPort
    IdentityServerAppSettings      = $config.IdentityServer.AppSettings
    SqlInstanceName                = $config.SqlServer.InstanceName
    SqlSourcePath                  = $config.SqlServer.SourcePath
    SqlFeatures                    = $config.SqlServer.Features
    SqlNativeUser                  = $config.SqlServer.NativeUser
    SqlSvcAccountCredential        = $SqlSvcCred
    SqlNativeUserCredential        = $SqlNativeCred
    DotNetVersion                  = $config.DotNet.Version
    DotNetSourcePath               = $config.DotNet.SourcePath
    ServiceAccountName             = $config.WindowsAccounts.ServiceAccount.Name
    ServiceAccountCredential       = $ServiceAcctCred
    DeveloperAccountOriginalName   = $config.WindowsAccounts.DeveloperAccount.OriginalName
    DeveloperAccountNewName        = $config.WindowsAccounts.DeveloperAccount.NewName
    DeveloperAccountCredential     = $DevAcctCred
    WebsiteName                    = 'OneStream' # Example, could also be in JSON
    WebsitePath                    = 'C:\inetpub\wwwroot\OneStream' # Example
    WebsitePort                    = 80 # Example
    OS_WallpaperPath               = $config.OperatingSystem.WallpaperPath
    OS_DefaultAppAssociationsPath  = $config.OperatingSystem.DefaultAppAssociationsPath
    OS_SplashScreenTaskPath        = $config.OperatingSystem.SplashScreenTaskPath
    OS_AutoLoadClientTaskPath      = $config.OperatingSystem.AutoLoadClientTaskPath
    OS_Culture                     = $config.OperatingSystem.Culture
    OS_EnsureSshServer             = $config.OperatingSystem.EnsureSshServer
    AdditionalSoftwarePackages     = $config.AdditionalSoftware.Packages
}

Start-OSLabBuild @buildParams
