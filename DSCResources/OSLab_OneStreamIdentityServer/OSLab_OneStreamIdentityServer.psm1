Configuration OSLab_OneStreamIdentityServer
{
    param
    (
        [Parameter(Mandatory)]
        [string]$ZipSourcePath,

        [Parameter(Mandatory)]
        [string]$InstallPath,

        [Parameter(Mandatory)]
        [string]$AppPoolName,

        [Parameter(Mandatory)]
        [uint32]$HttpPort,

        [Parameter(Mandatory)]
        [uint32]$HttpsPort,

        [Parameter(Mandatory)]
        [hashtable]$AppSettings,

        [string]$CertificateFriendlyName = 'OneStream Identity Server Self-Signed',

        [Parameter(Mandatory = $false)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )

    # Import required DSC modules
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'WebAdministrationDsc'
    Import-DscResource -ModuleName 'CertificateDsc' # UPDATED to use the supported module

    # 1. Ensure the target directory for the application exists
    File $InstallPath
    {
        DestinationPath = $InstallPath
        Type            = 'Directory'
        Ensure          = $Ensure
    }

    # 2. Extract the contents of the ZIP archive to the installation path
    Archive 'UnzipIdentityServer'
    {
        Ensure          = $Ensure
        Path            = $ZipSourcePath
        Destination     = $InstallPath
        DependsOn       = "[File]$($InstallPath)"
    }

    # 3. Create and configure the IIS Application Pool
    WebAppPool $AppPoolName
    {
        Ensure       = $Ensure
        Name         = $AppPoolName
        State        = 'Started'
        IdentityType = 'LocalSystem'
    }

    # 4. Create the IIS Website
    Website $AppPoolName
    {
        Ensure          = $Ensure
        Name            = $AppPoolName
        State           = 'Started'
        PhysicalPath    = $InstallPath
        ApplicationPool = $AppPoolName
        DependsOn       = '[Archive]UnzipIdentityServer', "[WebAppPool]$($AppPoolName)"
    }

    # 5. Create the self-signed certificate in the local machine's 'Personal' store
    Certificate 'CreateIdentityServerCert' # UPDATED resource name
    {
        Subject           = 'CN=localhost'
        FriendlyName      = $CertificateFriendlyName
        CertStoreLocation = 'Cert:\LocalMachine\My'
        DnsName           = 'localhost'
        Ensure            = $Ensure
    }

    # 6. Copy the certificate to the 'Trusted Root' store to avoid browser errors
    Script 'TrustIdentityServerCert'
    {
        GetScript = {
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $using:CertificateFriendlyName }
            if (-not $cert) { return @{ Result = $false } }
            $rootCert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
            return @{ Result = [bool]$rootCert }
        }
        SetScript = {
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $using:CertificateFriendlyName }
            $rootStore = Get-Item Cert:\LocalMachine\Root
            $rootStore.Open('ReadWrite')
            $rootStore.Add($cert)
            $rootStore.Close()
        }
        TestScript = {
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $using:CertificateFriendlyName }
            if (-not $cert) { return $false } # Prerequisite not met
            $rootCert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
            return [bool]$rootCert
        }
        DependsOn = '[Certificate]CreateIdentityServerCert' # UPDATED dependency
    }

    # 7. Configure the HTTPS binding using the new certificate's thumbprint
    Script 'ConfigureHttpsBinding'
    {
        GetScript = {
            $binding = Get-WebBinding -Name $using:AppPoolName -Port $using:HttpsPort -Protocol 'https' -ErrorAction SilentlyContinue
            return @{ Result = [bool]$binding }
        }
        SetScript = {
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $using:CertificateFriendlyName }
            # Using -SslFlags 1 for SNI support
            New-WebBinding -Name $using:AppPoolName -Protocol 'https' -Port $using:HttpsPort -SslFlags 1
            $binding = Get-WebBinding -Name $using:AppPoolName -Port $using:HttpsPort -Protocol 'https'
            $binding.AddSslCertificate($cert.Thumbprint, 'My')
        }
        TestScript = {
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $using:CertificateFriendlyName }
            if (-not $cert) { return $false } # Prerequisite not met

            $binding = Get-WebBinding -Name $using:AppPoolName -Port $using:HttpsPort -Protocol 'https' -ErrorAction SilentlyContinue
            if ($binding -and $binding.CertificateHash -eq $cert.Thumbprint) {
                return $true
            }
            return $false
        }
        DependsOn = '[Script]TrustIdentityServerCert', "[Website]$($AppPoolName)"
    }

    # 8. Dynamically create the appsettings.json file
    Script 'ConfigureAppSettingsJson'
    {
        GetScript = {
            $path = Join-Path $using:InstallPath 'appsettings.json'
            if (Test-Path $path) {
                # A simple hash comparison to check for changes
                $currentContent = Get-Content $path -Raw
                $newContent = $using:AppSettings | ConvertTo-Json -Depth 10
                return @{ Result = ($currentContent -eq $newContent) }
            }
            return @{ Result = $false }
        }
        SetScript = {
            $path = Join-Path $using:InstallPath 'appsettings.json'
            $using:AppSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8
        }
        TestScript = {
            $path = Join-Path $using:InstallPath 'appsettings.json'
            if (Test-Path $path) {
                # Compare current file content with desired state
                $currentContent = Get-Content $path -Raw
                $newContent = $using:AppSettings | ConvertTo-Json -Depth 10
                return ($currentContent -eq $newContent)
            }
            return $false
        }
        DependsOn = '[Script]ConfigureHttpsBinding'
    }
}
