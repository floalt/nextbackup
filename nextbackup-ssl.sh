#!/bin/bash

### Backup der Nextcloud-Datenbank und der Dateien auf SSH-Host
# author: flo.alt@fa-netz.de
# version: 0.8

# Achtung: für den SSH-User wird ein Zertifikat benötigt

#
# Bekannte Probleme:
#
# Die Sicherung der Datenbank wird im $NCPATH abgelegt und somit
# immer voll mitgesichert. Das benötigt u.u. viel Platz auf dem
# Backupspeicher.
# Und wenn auf $NCPATH fremde Dateien liegen, wird u.U. ein NC-Update blockiert
#

## Variablen definieren ##

# Datenpfade Nextcloud
NCPATH="/var/www/nextcloud"			# Nextcloud-Verzeichnis (Konfiguration und ggf. Daten)
DATAPATH="/mnt/daten/nextcloud"         	# Datenpfad Nextcloud (Backup from)
SCRIPTPATH="/usr/local/scripts/nextbackup/"	# Hier liegt dieses Script

# Datenbank-Backup
DBUSER="[dbuser]"			# Datenbank-User
DBPWD="[dbpass]"			# Passwort für Datenbank-User
DBNAME="nextcloud"			# Name der Nextcloud-Datenbank, z.B. nextcloud
DBBAK="$NCPATH"/.db-backup/nextcloud-sqlbackup.bak		# Ort und Datei für das Datanbank-Backup

# rdiff-backup
BAKHOST="[bakhost]"			# SSH-Host für Backup (Backup-Server)
BAKDIR="[bakdir]"	# Backup-Verzeichnis auf dem SSH-Host
BAKPATH="$BAKHOST"::"$BAKDIR"		# Backup-Stamm-Verzeichnis (Backup to)
SSHUSER="[sshuser]"				# SSH-User

# Prokokoll
LOGDIR=/var/log/nextbackup			# Log-Verzeichnis
STARTBAK="$(date +%d.%m.%Y-%H:%M)"	# Zeitstempel
SENDTO="[sento@mymail.com]"		# Mail-Empfänger für die Log-Datei
CUSTOMER="[Kunden-Name}"		# Kunden-Name

LOGFILE="$LOGDIR"/nextbackup-"$STARTBAK".log

touch "$SCRIPTPATH"/lastbackup-start

(

echo "Backup gestartet $(date +%d.%m.%Y-%H:%M)"
echo ""

## Datenbank-Dump erstellen ##


# Maintenance-Mode aktivieren
sudo -u www-data php "$NCPATH"/occ maintenance:mode --on

# Datenbank sichern

mv "$DBBAK" "$DBBAK"1
mysqldump --single-transaction -u "$DBUSER" -p"$DBPWD" "$DBNAME" > "$DBBAK"

if [ $? = 0 ]
	then
		echo "OK: Datenbank-Dump erfolgreich abgeschlossen"
	else
		echo "FEHLER: Fehler beim Ausführen des Datenbank-Dumps"
		echo "ABBRUCH: Backup fehlgeschlagen"
		sudo -u www-data php "$NCPATH"/occ maintenance:mode --off
		exit 1
fi

# Mantenance-Mode deaktivieren
sudo -u www-data php "$NCPATH"/occ maintenance:mode --off



## Vorraussetzungen für Backup prüfen ##

# Prüfe, ob Backup-Verzeichnis schreibbar ist

ssh $SSHUSER@$BAKHOST touch $BAKDIR/writetest

if [ $? = 0 ]
	then
		echo "OK: Schreibtest auf Backup-Verzeichnis erfolgreich"
		ssh $SSHUSER@$BAKHOST rm $BAKDIR/writetest
	else
		echo "FEHLER: kann nicht auf Backup-Verzeichnis schreiben"
		echo "ABBRUCH: Backup fehlgeschlagen"
		exit 1
fi


## Daten per rdiffbackup sichern ##

# Sicherung Konfiguration-Verzeichnis  ## incl. Daten

rdiff-backup --force --print-statistics -v0 "$NCPATH" $SSHUSER@"$BAKPATH"/nextcloud-config

if [ $? = 0 ]
	then
		echo "OK: Konfigurations-Backup incl. Daten erfolgreich abgeschlossen"
	else
		echo "FEHLER: Fehler beim Ausführen des Backups"
		echo "ABBRUCH: Backup fehlgeschlagen"
		exit 1
fi


Sicherung Daten-Verzeichnis

rdiff-backup --force --print-statistics -v0 "$DATAPATH" $SSHUSER@"$BAKPATH"/nextcloud-data

if [ $? = 0 ]
	then
		echo "OK: Daten-Backup erfolgreich abgeschlossen"
	else
		echo "FEHLER: Fehler beim Ausführen des Daten-Backups"
		echo "ABBRUCH: Backup fehlgeschlagen"
		exit 1
fi


## Abschluss des Backups ##

echo ""
echo "Backup beendet $(date +%d.%m.%Y-%H:%M)"
echo ""
echo "ENDE: Backup wurde erfolgreich erstellt"

) | tee "$LOGFILE"					# gesamte Ausgabe in Logfile schreiben
cp "$LOGFILE" $LOGDIR/nextbackup.log                        # aktuelles Logfile fürs Monitoring kopieren
find "$LOGDIR"/* -mtime +365 -exec rm {} +		# Logdateien, älter als 1 Jahr löschen
touch "$SCRIPTPATH"/lastbackup-stop			# Marker-File für Backup-Ende setzen

cat $LOGFILE | mail -s "Nexcloud-Backup $CUSTOMER" $SENDTO


exit 0