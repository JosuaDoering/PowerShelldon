<#
    .SYNOPSIS
    Copys files to another folder. 

    .DESCRIPTION
    By using a OneDrive or GDrive client, backups can be uploaded to the cloud via this script. 

    .LINK
    Created by: www.josua-doering.de
#>

$PathToBackup = ""
$PathForBackup = ""
$CurrentDate = Get-Date -Format 'yyyy-MM-dd'
$BackupFrequency = 1 #days
$BackupRetention = 14 #days

### Remove old backups (older than $BackupRetention)
$oldBackupsToRemove = Get-ChildItem -Path $PathForBackup | Where-Object { $PSItem.CreationTime -lt (Get-Date).AddDays(-$BackupRetention) }
if ($oldBackupsToRemove) {
    Remove-Item -Path $oldBackupsToRemove -Confirm:$false
    Write-Output "Removed backups older than $BackupRetention days"
}

### Backup new files from system
$filesToBackup = Get-ChildItem -Path $PathToBackup | Sort-Object LastWriteTime -Descending

if (((Get-Date) - $filesToBackup[0].LastWriteTime).Days -lt $BackupFrequency) {
    if (-not (Test-Path -Path "$PathForBackup/$CurrentDate")) {
        New-Item -Path $PathForBackup -Name $CurrentDate -ItemType Directory -Confirm:$false

        $filesToBackup | Copy-Item -Destination "$PathForBackup/$CurrentDate" -Confirm:$false
        Write-Output "New files backed up"
    }
    else {
        Write-Output "Backup for today $CurrentDate already saved"
    }
}