@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            Role     = 'OneStreamLabServer'
        }
    )

    NonNodeData = @{
        OneStreamVersion   = '8.2.0'
        OneStreamSourcePath = 'C:\Install\OneStream\OneStream_8.2.0.msi'
        OneStreamInstallPath = 'C:\Program Files\OneStream Software\OneStream'
        WebsiteName         = 'OneStream'
        WebsitePort         = 80
        WebsitePath         = 'C:\inetpub\wwwroot\OneStream'
        SqlInstanceName     = 'MSSQLSERVER'
        SqlSourcePath       = 'C:\Install\SQLServer'
        SqlFeatures         = 'SQLENGINE,SSMS'
        DbConnectionString  = 'Data Source=localhost;Initial Catalog=OneStream;Integrated Security=True;'
    }
}
