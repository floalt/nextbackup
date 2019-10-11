# nextbackup: Nextcloud Backup
A shell backup script for nextcloud

----

## Description
- This script is for backup my Nextcloud-Server with rdiff-backup on a local iscsi-device or a remote ssh-host
- logfiles are created and sent by email

### Step-by-step
1. creates marker file `$SCRIPTPATH/lastbackup-start`
2. checks if backup destination is there
3. performs database backup
4. performs server configuration backup
5. performs backup of data files
6. creates marker file `$SCRIPTPATH/lastbackup-stop`
7. sends out logfile

### Directories

Description               | Path
--------------------------|--------------------------------
home of the script        | /usr/local/scripts/nextbackup/
logfiles                  | /var/log/nextbackup/
destination: data files   | $BACKPATH/nextcloud-data/
destination: config files | $BACKPATH/nextcloud-config/
destination: database     | $BACKPATH/database/

----

## Reqirements

- working email configuration for sending logfile
- in case of backup destination iSCSI: working iSCSI configuration
- in case of backup destination SSH: accessing remote-host by ssh certificate

----

## Installation

1. Copy to `/usr/local/scripts/nextbackup`
2. make executeable: `sudo chmod 750 nextbackup.sh`
3. set crontab `sudo crontab -e` (e.g. daily 2:00)
4. create these folders:
    - $BACKPATH/nextcloud-data/
    - $BACKPATH/nextcloud-config/
    - $BACKPATH/database/
    - /var/log/nextbackup
