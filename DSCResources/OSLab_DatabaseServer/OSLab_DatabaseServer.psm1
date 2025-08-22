Configuration OSLab_DatabaseServer
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$InstanceName,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$Features,

        [Parameter(Mandatory = $true)]
        [PSCredential]$SqlSvcAccount
    )

    Import-DscResource -ModuleName 'SqlServer'

    SqlSetup 'InstallDefaultInstance'
    {
        InstanceName = $InstanceName
        SourcePath   = $SourcePath
        Features     = $Features
        SqlSvcAccount = $SqlSvcAccount
        InstallSqlDataDir = "C:\\Program Files\\Microsoft SQL Server"
    }
}
