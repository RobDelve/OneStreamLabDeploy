Configuration OSLab_WebServer
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$WebsiteName,

        [Parameter(Mandatory = $true)]
        [string]$PhysicalPath,

        [Parameter(Mandatory = $true)]
        [uint32]$Port,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'WebAdministrationDSC'

    $webServerFeatures = @(
        "Web-Server", "Web-WebServer", "Web-Common-Http", "Web-Default-Doc",
        "Web-Dir-Browsing", "Web-Http-Errors", "Web-Static-Content", "Web-Health",
        "Web-Http-Logging", "Web-Performance", "Web-Stat-Compression", "Web-Dyn-Compression",
        "Web-Security", "Web-Filtering", "Web-Windows-Auth", "Web-App-Dev",
        "Web-Net-Ext45", "Web-Asp-Net45", "Web-ISAPI-Ext", "Web-ISAPI-Filter",
        "Web-Mgmt-Tools", "Web-Mgmt-Console", "Web-Mgmt-Compat", "Web-Metabase"
    )

    foreach ($feature in $webServerFeatures) {
        WindowsFeature $feature
        {
            Ensure = $Ensure
            Name = $feature
        }
    }

    Website $WebsiteName
    {
        Ensure       = $Ensure
        Name         = $WebsiteName
        State        = "Started"
        PhysicalPath = $PhysicalPath
        BindingInfo  = MSFT_xWebBindingInformation
                       {
                           Protocol = "http"
                           Port     = $Port
                       }
        DependsOn    = "[WindowsFeature]Web-Server"
    }
}
