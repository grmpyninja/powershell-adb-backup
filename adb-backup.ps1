# Author: grmpyninja <grmpyninja@gmail.com>

# TODO: get ADB via powershell and unpack it
# https://dl.google.com/android/repository/platform-tools-latest-windows.zip
# TODO: Add a link to tutorial to turn on debugging on Android
# TODO: Add a link to tutorial to install USB drivers if necessary

# ScriptBLock that does the actual backup
$do_backup = {

    param(
            $packageObject, # Object with properties Package, Path, Type
            $jobFile,       # File used to synchronize PowerShell Jobs. STDOUT from adb is saved in that file
            $backupDir,     # Backup directory
            $adbDir         # Directory where ADB is stored
         )
    
    $log_file = [System.IO.Path]::Combine($adbDir.Path, "backup.log")

    # Change directory to ADB's main directory
    # TODO: fix it to simply invoke ADB using a full path
    cd $adbDir

    # Prepare a full path for AndroidBackup file. 
    # Format <BACKUP_DIR>\<package>_yyyy-MM-dd_HH_mm_ss.ab
    $ab_path = [System.IO.Path]::Combine($backupDir, $packageObject.Package + '_' + $(get-date -f yyyy-MM-dd_HH_mm_ss) + '.ab')

    # ADB command to do backup. Add or remove -apk if you jobFile
    .\adb.exe backup -f $ab_path $packageObject.Package >> $jobFile

    # Log packages which were not successfully backuped
    if ((Get-Item $ab_path).length -eq 0) {
        "BACKUP FAILED: " + $packageObject.Package + " to " + $ab_path >> $log_file 
    } else {
        "BACKUP SUCCESS: " + $packageObject.Package + " to " + $ab_path >> $log_file
    }
}


# TODO: add adb_dir to ADB invocation
function backup($packages_list, $back_dir, $adb_dir) {
    
    # Create backups directory
    New-Item -ItemType Directory -Force -Path $back_dir

    foreach ($p in $packages_list) {

        # Get counter to show nice progress bar :)
        $i = $packages_list.IndexOf($p) + 1
        "BACKUP-START {0} ({1}/{2})" -f $p.Package,$i,$packages_list.Count

        # Generate synchronization JOB file in TEMP directory and pass it to JOB
        #$job_file = [System.IO.Path]::GetTempFileName()
        #New-Item -ItemType File -Path 

        $job_file = "job.lock"
        if (Test-Path $job_file) {
            rm $job_file
        }

        $job = start-job $do_backup -ArgumentList @($p, $job_file, $back_dir, $adb_dir)

        # Wait for JOB to start backup on Android and wait for backup confirmation msg 
        $output = ""
        do {
            Start-Sleep -Seconds 1
            if (Test-Path $job_file) {
                $output = Get-Content $job_file
            }
        } while ([string]::IsNullOrEmpty($output) -or !$output.Contains("Now unlock your device and confirm the backup"))
        
        # Confirm backup
        #http://android.stackexchange.com/questions/36224/backup-using-adb-on-a-phone-with-a-dead-screen
        .\adb.exe shell input keyevent 22
        .\adb.exe shell input keyevent 23

        # Supress wait-job output via variable assignment
        $o = Wait-job $job
        stop-job $job
        remove-job $job

        # Remove JOB synchronization temp file
        rm $job_file

        "BACKUP-DONE {0} ({1}/{2})" -f $p.Package,$i,$packages_list.Count
    }
}


# Helper function to get all files from BACKUP directory with size==0
# Filename format is strict
function get_empty_ab($dir) {
    $zero_size_files = Get-ChildItem $dir | ? { $_.Length -eq 0} | %{ $_.Name.Split('_')[0] } | sort -Unique
    return $packages | ?{ $zero_size_files.Contains($_.Package) }
}


# List packages
# The assumption is that ADB.exe is in the current directory
$raw_adb_packages_list = .\adb shell "pm list packages -f" 
$packages = $raw_adb_packages_list | ? {$_.trim() -ne "" } | %{ $x=$_.Split(':'); New-Object PSObject -Property @{Type=$x[0]; Path=$x[1].split('=')[0]; Package=$x[1].split('=')[1]} }

# $packages contains all packages installed on the device

# Example filtering
# $to_backup = $packages | select -first 20
# $to_backup = $packages | ?{ $_.Package.StartsWith("com.google.android") }

# Exmple do backup
# PARAMETERS for script
$adb_dir = $(Get-Location)
$back_dir = join-path $(Get-Location) 'backups'
$to_backup = $packages | select -first 5
backup $to_backup $back_dir $adb_dir

# Make sure phone won't get locked during the process. 
# Otherwise files will be incorrectly dumped (size==0) or it'll simply hang till unlock.
# Caffeeine is a good way to prevent locking the phone during the backup. 

# Example to get packages for which AB files got size==0
# so were incorrectly dumped, for DEBUG purposes
# get_empty_ab $back_dir

# Steps to use:
# 0. Launch PowerShell ISE and open adb-backup.ps1 file. Make sure you got the right policy to launch scripts.
# 1. Adjust backup parameters. 
# 2. Download and unpack https://dl.google.com/android/repository/platform-tools-latest-windows.zip and cd to that directory in PowerShell ISE
# 3. .\adb devices -l
# 4. Make sure your device is authorized
# 5. Install Caffeine or any other app that will prevent your phone getting locked in the middle of the process
# 6. Try to launch the script and see how popups are displayed on your mobile phone and are automatically confirmed
