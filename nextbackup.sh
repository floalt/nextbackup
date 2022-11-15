#!/bin/bash

### Backup der Nextcloud-Datenbank, Konfigurations-Dateien und der User-Daten

# description
#   Dieses Script sichert alle Daten per rdiff-backup auf ein lokales Laufwerk, z.B. über iSCSI
#    1. Dump der Datenbank
#    2. Sicherung der Konfigurations-Dateien
#    3. Sicherung der User-Daten

# author: flo.alt@fa-netz.de
# version: 0.93


## first steps

	# read config

	SCRIPTPATH=$(dirname "$(readlink -e "$0")")
	SCRIPTNAME="$(basename $(realpath $0))"

	source $SCRIPTPATH/config

	# prepare for start

	STARTBAK="$(date +%d.%m.%Y-%H:%M)"	# Zeitstempel
	LOGFILE="$LOGDIR"/nextbackup-"$STARTBAK".log
	ERRFILE="$LOGDIR"/error-"$STARTBAK".log

	if [ ! -d $LOGDIR ]; then mkdir -p $LOGDIR; fi



## start the logfile

	touch "$SCRIPTPATH"/lastbackup-start

	(
	echo "Protokolldatei vom täglichen Nextcloud-Backup";echo "ausgeführt von $SCRIPTPATH/nextbackup.sh";echo ""
	echo "Backup gestartet $(date +%d.%m.%Y-%H:%M)";echo ""



## Vorraussetzungen für Backup prüfen ##

	# Prüfe, ob Backup-Verzeichnis schreibbar ist

		touch "$BAKPATH"/writetest

		if [ $? = 0 ];then
			echo "OK: Schreibtest auf Backup-Verzeichnis erfolgreich" >> $LOGFILE
			rm "$BAKPATH"/writetest
		else
			echo "FEHLER: kann nicht auf Backup-Verzeichnis schreiben" >> $ERRFILE
			echo "ABBRUCH: Backup fehlgeschlagen" >> $ERRFILE
			ERRORMARKER=yes
		fi

## Datenbank-Dump erstellen ##

	# Maintenance-Mode aktivieren
	
		sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

	# Datenbank sichern

		mv "$DBBAKPATH"/"$DBBAKFILE" "$DBBAKPATH"/"$DBBAKFILE"1
		mysqldump --single-transaction -u "$DBUSER" -p"$DBPWD" "$DBNAME" > "$DBBAKPATH"/"$DBBAKFILE"

		if [ $? = 0 ]
			then
				echo "OK: Datenbank-Dump erfolgreich abgeschlossen"
			else
				echo "FEHLER: Fehler beim Ausführen des Datenbank-Dumps"
				echo "ABBRUCH: Backup fehlgeschlagen"
				sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
				exit 1
		fi

	# Mantenance-Mode deaktivieren
	
		sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off



## Daten per rdiffbackup sichern ##

	# Sicherung Konfiguration-Verzeichnis

		rdiff-backup --force --print-statistics -v0 /var/www/nextcloud "$BAKPATH"/nextcloud-config

		if [ $? = 0 ]
			then
				echo "OK: Konfigurations-Backup erfolgreich abgeschlossen"
			else
				echo "FEHLER: Fehler beim Ausführen des Konfigurations-Backups"
				echo "ABBRUCH: Backup fehlgeschlagen"
				exit 1
		fi


	# Sicherung Daten-Verzeichnis

		rdiff-backup --force --print-statistics -v0 "$DATAPATH" "$BAKPATH"/nextcloud-data

		if [ $? = 0 ]
			then
				echo "OK: Daten-Backup erfolgreich abgeschlossen"
			else
				echo "FEHLER: Fehler beim Ausführen des Daten-Backups"
				echo "ABBRUCH: Backup fehlgeschlagen"
				exit 1
		fi


## Retention Time

	echo ""
	echo "Backups älter als $RETENTION werden gelöscht..."
	rdiff-backup --remove-older-than $RETENTION --force "$DBBAKPATH"
	rdiff-backup --remove-older-than $RETENTION --force "$BAKPATH"/nextcloud-config
	rdiff-backup --remove-older-than $RETENTION --force "$BAKPATH"/nextcloud-data

	if [ $? = 0 ]
		then
			echo "OK: Alte Backups erfolgreich abgeschlossen"
		else
			echo "FEHLER: Fehler beim löschen alter Backups"
	fi

## Abschluss des Backups ##

	echo ""
	echo "Backup beendet $(date +%d.%m.%Y-%H:%M)"
	echo ""
	echo "ENDE: Backup wurde erfolgreich erstellt"

	) | tee "$LOGFILE"					# gesamte Ausgabe in Logfile schreiben
	find "$LOGDIR"/* -mtime +365 -exec rm {} + 		# Logdateien, älter als 1 Jahr löschen
	touch "$SCRIPTPATH"/lastbackup-stop			# Marker-File für Backup-Ende setzen

	cat $LOGFILE | mail -s "Nexcloud-Backup $CUSTOMER" $SENDTO


	exit 0
