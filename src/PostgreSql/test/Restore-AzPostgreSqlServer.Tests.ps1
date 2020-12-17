$loadEnvPath = Join-Path $PSScriptRoot 'loadEnv.ps1'
if (-Not (Test-Path -Path $loadEnvPath)) {
    $loadEnvPath = Join-Path $PSScriptRoot '..\loadEnv.ps1'
}
. ($loadEnvPath)
$TestRecordingFile = Join-Path $PSScriptRoot 'Restore-AzPostgreSqlServer.Recording.json'
$currentPath = $PSScriptRoot
while(-not $mockingPath) {
    $mockingPath = Get-ChildItem -Path $currentPath -Recurse -Include 'HttpPipelineMocking.ps1' -File
    $currentPath = Split-Path -Path $currentPath -Parent
}
. ($mockingPath | Select-Object -First 1).FullName

# !Important: some test cases are skipped and require to be recorded again
# See https://github.com/Azure/autorest.powershell/issues/580
Describe 'Restore-AzPostgreSqlServer' {
    It 'GeoRestore' -Skip {
        $replica = Get-AzPostgreSqlServer -ResourceGroupName $env.resourceGroup -ServerName $env.serverName | New-AzPostgreSqlReplica -Name $env.replicaName -ResourceGroupName $env.resourceGroup
        # Possible bug: above line should be
        # $replica = Get-AzPostgreSqlServer -ResourceGroupName $env.resourceGroup -ServerName $env.serverName | Get-AzPostgreSqlReplica -Name $env.replicaName -ResourceGroupName $env.resourceGroup
        $restoreServer = Restore-AzPostgreSqlServer -Name $env.serverName -ResourceGroupName $env.resourceGroup -InputObject $replica -UseGeoRestore 
        $restoreServer.Name | Should -Be $env.serverName
        $restoreServer.SkuName | Should -Be $env.Sku
    }

    It 'PointInTimeRestore' {
        $restorePointInTime = (Get-Date).AddMinutes(-10)
        $restoreServer = Get-AzPostgreSqlServer -ResourceGroupName $env.resourceGroup -ServerName $env.serverName | Restore-AzPostgreSqlServer -Name $env.restoreName2 -ResourceGroupName $env.resourceGroup -RestorePointInTime $restorePointInTime -UsePointInTimeRestore
        $restoreServer.Name | Should -Be $env.restoreName2
        $restoreServer.SkuName | Should -Be $env.Sku
    }
}
