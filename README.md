# Pure PowerShell and ADB script to backup applications

## Requirements 

- [opt] PowerShell ISE allows to easily hack the script
- [goole official adb for windows link](https://dl.google.com/android/repository/platform-tools-latest-windows.zip)
- basic knowledge of PowerShell and the desire to read comments in the code

# HOWTO

Script's parameters are somewhere almost at the end of the script and by default when everything is simply correctly launched, 
it will list all installed pacakges (in variable `$packages`) and backup first 5 of them under `<ADB_DIR>\backup` directory

**Parameters section in the script** and `backup` function invocation 

```ps1
...
# PARAMETERS for script
$adb_dir = $(Get-Location)
$back_dir = join-path $(Get-Location) 'backups'
$to_backup = $packages | select -first 5
backup $to_backup $back_dir $adb_dir
...
```

## Ways to filter packages which can be passed to `backup` function

```ps1
# Example filtering - first 20 packages
$to_backup = $packages | select -first 20
# Example filtering - starting with "com.google.android"
$to_backup = $packages | ?{ $_.Package.StartsWith("com.google.android") }
```

## General tips

- Make sure phone won't get locked during the process otherwise files will be incorrectly dumped (`size==0`)
- [Caffeeine](https://play.google.com/store/apps/details?id=nl.syntaxa.caffeine&hl=en) is a good way to prevent locking the phone during the backup 

If some files got `size==0` there is an easy way to list those packages using the following code and try to backup them again

```
$broken_ab_files = get_empty_ab $back_dir
backup $broken_ab_files $back_dir $adb_dir
```

## Steps to use this tool

0. Launch PowerShell ISE and open adb-backup.ps1 file. Make sure you got the right policy to launch scripts.
1. Adjust backup parameters. 
2. Download and unpack [official google adb for windows](https://dl.google.com/android/repository/platform-tools-latest-windows.zip) and `cd` to that directory in PowerShell ISE
3. `.\adb devices -l`
4. Make sure your PC device is authorized on the device
5. Install [Caffeeine](https://play.google.com/store/apps/details?id=nl.syntaxa.caffeine&hl=en) or any other app that will prevent your phone getting locked in the middle of the process
6. Try to launch the script and see how popups are displayed on your mobile phone and are automatically confirmed
