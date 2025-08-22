function Start-OSLabBuild {
    [CmdletBinding()]
    param (
        # OneStream App Server Parameters
        [Parameter(Mandatory)] [string]$OneStreamVersion,
        [Parameter(Mandatory)] [string]$OneStreamSourcePath,
        [Parameter(Mandatory)] [string]$OneStreamInstallPath,
        [Parameter(Mandatory)] [string]$OneStreamLicenseKeyPath,
        [Parameter(Mandatory)] [hashtable]$OneStreamAppSettings,
        [Parameter(Mandatory)] [hashtable]$OneStreamGatewayConfig,
        [Parameter(Mandatory)] [string[]]$OneStreamEnsureFolders,

        # OneStream Identity Server Parameters
        [Parameter(Mandatory)] [string]$IdentityServerZipSourcePath,
        [Parameter(Mandatory)] [string]$IdentityServerInstallPath,
        [Parameter(Mandatory)] [string]$IdentityServerAppPoolName,
        [Parameter(Mandatory)] [uint32]$IdentityServerHttpPort,
        [Parameter(Mandatory)] [uint32]$IdentityServerHttpsPort,
        [Parameter(Mandatory)] [hashtable]$IdentityServerAppSettings,

        # SQL Server Parameters
        [Parameter(Mandatory)] [string]$SqlInstanceName,
        [Parameter(Mandatory)] [string]$SqlSourcePath,
        [Parameter(Mandatory)] [string]$SqlFeatures,
        [Parameter(Mandatory)] [string]$SqlNativeUser,
        [Parameter(Mandatory)] [pscredential]$SqlSvcAccountCredential,
        [Parameter(Mandatory)] [pscredential]$SqlNativeUserCredential,

        # .NET Parameters
        [Parameter(Mandatory)] [string]$DotNetVersion,
        [Parameter(Mandatory)] [string]$DotNetSourcePath,

        # Windows Account Parameters
        [Parameter(Mandatory)] [string]$ServiceAccountName,
        [Parameter(Mandatory)] [pscredential]$ServiceAccountCredential,
        [Parameter(Mandatory)] [string]$DeveloperAccountOriginalName,
        [Parameter(Mandatory)] [string]$DeveloperAccountNewName,
        [Parameter(Mandatory)] [pscredential]$DeveloperAccountCredential,

        # Web Server Parameters (for the main OneStream site)
        [Parameter(Mandatory)] [string]$WebsiteName,
        [Parameter(Mandatory)] [string]$WebsitePath,
        [Parameter(Mandatory)] [uint32]$WebsitePort,

        # Operating System Parameters
        [Parameter(Mandatory)] [string]$OS_WallpaperPath,
        [Parameter(Mandatory)] [string]$OS_DefaultAppAssociationsPath,
        [Parameter(Mandatory)] [string]$OS_SplashScreenTaskPath,
        [Parameter(Mandatory)] [string]$OS_AutoLoadClientTaskPath,
        [Parameter(Mandatory)] [string]$OS_Culture,
        [Parameter(Mandatory)] [boolean]$OS_EnsureSshServer,

        # Additional Software Parameters
        [Parameter(Mandatory)] [string[]]$AdditionalSoftwarePackages
    )

    # Dynamically create the ConfigurationData hashtable from all function parameters
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                       = 'localhost'
                Role                           = 'OneStreamLabServer'
                OneStreamVersion               = $OneStreamVersion
                OneStreamSourcePath            = $OneStreamSourcePath
                OneStreamInstallPath           = $OneStreamInstallPath
                OneStreamLicenseKeyPath        = $OneStreamLicenseKeyPath
                OneStreamAppSettings           = $OneStreamAppSettings
                OneStreamGatewayConfig         = $OneStreamGatewayConfig
                OneStreamEnsureFolders         = $OneStreamEnsureFolders
                IdentityServerZipSourcePath    = $IdentityServerZipSourcePath
                IdentityServerInstallPath      = $IdentityServerInstallPath
                IdentityServerAppPoolName      = $IdentityServerAppPoolName
                IdentityServerHttpPort         = $IdentityServerHttpPort
                IdentityServerHttpsPort        = $IdentityServerHttpsPort
                IdentityServerAppSettings      = $IdentityServerAppSettings
                SqlInstanceName                = $SqlInstanceName
                SqlSourcePath                  = $SqlSourcePath
                SqlFeatures                    = $SqlFeatures
                SqlNativeUser                  = $SqlNativeUser
                SqlSvcAccountCredential        = $SqlSvcAccountCredential
                SqlNativeUserCredential        = $SqlNativeUserCredential
                DotNetVersion                  = $DotNetVersion
                DotNetSourcePath               = $DotNetSourcePath
                ServiceAccountName             = $ServiceAccountName
                ServiceAccountCredential       = $ServiceAccountCredential
                DeveloperAccountOriginalName   = $DeveloperAccountOriginalName
                DeveloperAccountNewName        = $DeveloperAccountNewName
                DeveloperAccountCredential     = $DeveloperAccountCredential
                WebsiteName                    = $WebsiteName
                WebsitePath                    = $WebsitePath
                WebsitePort                    = $WebsitePort
                OS_WallpaperPath               = $OS_WallpaperPath
                OS_DefaultAppAssociationsPath  = $OS_DefaultAppAssociationsPath
                OS_SplashScreenTaskPath        = $OS_SplashScreenTaskPath
                OS_AutoLoadClientTaskPath      = $OS_AutoLoadClientTaskPath
                OS_Culture                     = $OS_Culture
                OS_EnsureSshServer             = $OS_EnsureSshServer
                AdditionalSoftwarePackages     = $AdditionalSoftwarePackages
                DbConnectionString             = "Data Source=$($env:COMPUTERNAME);Initial Catalog=OneStream;User ID=$($SqlNativeUser);Password=$($SqlNativeUserCredential.GetNetworkCredential().Password)"
            }
        )
    }

    # Define the main DSC Configuration that orchestrates all resources
    Configuration OneStreamLab
    {
        Import-DscResource -ModuleName 'OneStreamLabDeploy'
        Import-DscResource -ModuleName 'SqlServerDsc'
        Import-DscResource -ModuleName 'WebAdministrationDsc'
        Import-DscResource -ModuleName 'PkiDsc'
        Import-DscResource -ModuleName 'ChocolateyManagementDsc'

        Node $AllNodes.NodeName
        {
            OSLab_WebServer 'WebServer' {
                WebsiteName  = $Node.WebsiteName
                PhysicalPath = $Node.WebsitePath
                Port         = $Node.WebsitePort
            }

            OSLab_DatabaseServer 'DatabaseServer' {
                InstanceName  = $Node.SqlInstanceName
                SourcePath    = $Node.SqlSourcePath
                Features      = $Node.SqlFeatures
                SqlSvcAccount = $Node.SqlSvcAccountCredential
            }

            SqlServerLogin 'SqlNativeUser' {
                InstanceName = $Node.SqlInstanceName
                Name         = $Node.SqlNativeUser
                Password     = $Node.SqlNativeUserCredential
                Ensure       = 'Present'
                DependsOn    = '[OSLab_DatabaseServer]DatabaseServer'
            }

            OSLab_DotNetHostingBundle 'DotNet' {
                Version    = $Node.DotNetVersion
                SourcePath = $Node.DotNetSourcePath
            }

            OSLab_LocalUserAccount 'ServiceAccount' {
                UserName = $Node.ServiceAccountName
                Password = $Node.ServiceAccountCredential
                Ensure   = 'Present'
            }

            OSLab_LocalUserAccount 'DeveloperAccount' {
                UserName = $Node.DeveloperAccountOriginalName
                NewName  = $Node.DeveloperAccountNewName
                Password = $Node.DeveloperAccountCredential
                Ensure   = 'Present'
            }

            OSLab_OperatingSystem 'OSConfiguration' {
                WallpaperPath              = $Node.OS_WallpaperPath
                DefaultAppAssociationsPath = $Node.OS_DefaultAppAssociationsPath
                SplashScreenTaskPath       = $Node.OS_SplashScreenTaskPath
                AutoLoadClientTaskPath     = $Node.OS_AutoLoadClientTaskPath
                Culture                    = $Node.OS_Culture
                EnsureSshServer            = $Node.OS_EnsureSshServer
                EnableAutoLogon            = $true
                AutoLogonCredential        = $Node.DeveloperAccountCredential
                DisableEdgePasswordManager = $true
                DependsOn                  = '[OSLab_LocalUserAccount]DeveloperAccount'
            }

            OSLab_AdditionalSoftware 'ExtraTools' {
                PackageNames = $Node.AdditionalSoftwarePackages
            }

            OSLab_OneStreamAppServer 'OneStreamAppServer' {
                Version          = $Node.OneStreamVersion
                SourcePath       = $Node.OneStreamSourcePath
                InstallPath      = $Node.OneStreamInstallPath
                ConnectionString = $Node.DbConnectionString
                LicenseKeyPath   = $Node.OneStreamLicenseKeyPath
                AppSettings      = $Node.OneStreamAppSettings
                GatewayConfig    = $Node.OneStreamGatewayConfig
                EnsureFolders    = $Node.OneStreamEnsureFolders
                DependsOn        = '[SqlServerLogin]SqlNativeUser', '[OSLab_DotNetHostingBundle]DotNet'
            }

            OSLab_OneStreamIdentityServer 'IdentityServer' {
                ZipSourcePath = $Node.IdentityServerZipSourcePath
                InstallPath   = $Node.IdentityServerInstallPath
                AppPoolName   = $Node.IdentityServerAppPoolName
                HttpPort      = $Node.IdentityServerHttpPort
                HttpsPort     = $Node.IdentityServerHttpsPort
                AppSettings   = $Node.IdentityServerAppSettings
                DependsOn     = '[OSLab_WebServer]WebServer', '[OSLab_DotNetHostingBundle]DotNet'
            }
        }
    }

    # Compile the configuration into a MOF file
    $mofPath = Join-Path -Path $PSScriptRoot -ChildPath 'DSC'
    OneStreamLab -ConfigurationData $ConfigurationData -OutputPath $mofPath

    # Apply the configuration to the local machine
    Start-DscConfiguration -Path $mofPath -Wait -Verbose -Force
}
