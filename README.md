# nextbackup
A shell backup script for nextcloud

### description
This script is for backup my Nextcloud-Server with rdiff-backup on a local iscsi-device
1. Backup data incremental rdiff-backup
2. SQL-Dump
3. Backup database dump, keep only 2 versions
4. Sends a mail with the logfile

### usage
- In the first part of the script you have to set the variables
- Then add it to cronjob and be happy
