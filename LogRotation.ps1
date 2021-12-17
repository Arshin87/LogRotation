# DATA STRUCTURE
$global:data = [PSCustomObject]@{
    "Logs" = @{
        'Folders'        = @{
            'LogFolders'     = @();
            'BackupFolders'     = @();
        };
    }
}

function clear-datastr {
    $global:data = [PSCustomObject]@{
        "Logs" = @{
            'Folders'        = @{
                'LogFolders'     = @();
                'BackupFolders'     = @();
            };
        }
    }
}

$LogLocation = 'E:\Logs-iis\'
$BackupLocation = 'E:\Logs-backup\'

#Checks if Logs-iis and Logs-backups holds same folders. If not it creates the missing folders in logs-backup
function Create-Folders($log) {
    $backF = $data.Logs.Folders.BackupFolders

    $sizeOfBackupFolder = Get-ChildItem $BackupLocation | Measure-Object

    foreach($folder in $log){
        if($sizeOfBackupFolder.Count -lt 1){
        
          #  foreach($folder in $data.Logs.Folders.LogFolders.Name){
                if(!(Test-Path -Path $BackupLocation\$folder)){
                    New-Item -Path $BackupLocation -Name $folder -ItemType "directory"
                }
    
         #   }
        }else {
            if(!(Test-Path -Path $BackupLocation\$folder)){
                Test-Path -Path $BackupLocation\$folder
                if(Compare-Object -ReferenceObject $backF.Name -DifferenceObject $folder){
 
                    New-Item -Path $BackupLocation -Name $folder -ItemType "directory"
                }
            }
        }
    }
    
    
}

#Gets folder names in log locaiton, adds it to datastr LogFolders
function get-logfolders($selectFolders) {
    $Logfolders = Get-ChildItem -Path $selectFolders
    $Logfolders = $Logfolders.FullName
    foreach($folder in $Logfolders){
        $global:data.Logs.Folders.LogFolders += [pscustomobject]@{Name = $folder.Name; path = $folder.FullName}; 
    }
}
#Gets folder names in backup locaiton, adds it to datastr BackupFolders
function get-BackupFolders($folderSelect) {
    $Backupfolders = Get-ChildItem -Path $folderSelect
    foreach($folder in $Backupfolders){
        $global:data.Logs.Folders.BackupFolders += [pscustomobject]@{Name = $folder.Name; path = $folder.FullName}; 
    }
}

#Search for files older than specified age in specified folder.
function get-oldFiles($location, $age) {

    Set-Location $location
    write-host -ForegroundColor Green "Searching: $($location) and objects older than $($age) days"
    foreach($folder in $data.Logs.Folders.LogFolders.Path){
        $oldFile = Get-ChildItem -File -Recurse | Where-Object{$_.LastWriteTime -le (Get-Date).AddDays(-$age)}
        return $oldFile
    }
   
    
}

#Moves files to specified folder for backup.
function move-ToBackup($Files) {
 
    if($Files){
        Write-Host "Moving Old files to backupfolder" -ForegroundColor Green
        write-host -ForegroundColor Green "$($files.count) Files Moved to backup"
        foreach($File in $Files){
  
            $location = $BackupLocation+(get-item $file.FullName).Directory.Name
            Set-Location $BackupLocation
            Move-Item $file.FullName -Destination $location
        }
    }else{
        write-host "No Files to Move" -ForegroundColor Red 
    }
}

#Removes backups after specified time.
function remove-backup($Files) {
    if($Files){
        write-host -ForegroundColor Green "$($files.count) Files Removed"
        Remove-Item $Files
    }else {
        Write-Host -ForegroundColor red "No Files to remove"
    }
}

################################
#  START
################################
clear-datastr
get-BackupFolders $BackupLocation
get-logfolders $LogLocation
Create-Folders($data.Logs.Folders.LogFolders.Name)

move-ToBackup(get-OldFiles $LogLocation 3)
remove-backup(get-oldFiles $BackupLocation 45)