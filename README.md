# nextbackup: Nextcloud Backup
A shell backup script for nextcloud

### Description
This script is for backup my Nextcloud-Server with rdiff-backup on a local iscsi-device
1. Backup data incremental rdiff-backup
2. SQL-Dump
3. Backup database dump, keep only 2 versions
4. Sends a mail with the logfile

### Reqirements

- working email configuration for sending logfile
- in case of backup destination iSCSI: working iSCSI configuration
- in case of backup destination SSH: accessing remote-host by ssh certificate

### Installation

1. Copy to `/usr/local/scripts/nextbackup`
2. make executeable: `sudo chmod 750 nextbackup.sh`
3. set crontab `sudo crontab -e` (e.g. daily 2:00)
4. create these folders:
    - $BACKPATH/nextcloud-data/
    - $BACKPATH/nextcloud-config/
    - $BACKPATH/database/
    - /var/log/nextbackup
