#!/bin/bash

# description: database dump Nextcloud-DB
# author: flo.alt@fa-netz.de
# version: 0.6

# unset variables
    unset errorcount
    unset failcount
    unset thiserrcount

# read config
    scriptpath=$(dirname "$(readlink -e "$0")")
    scriptname="$(basename $(realpath $0))"

    # scriptpath="/home/flo/scripts/nextbackup"
    # scriptname="nextdump.sh"

    source $scriptpath/nextdump.config


# set some variables
    errorcount=0
    failcount=0
    thiserrcount=0
    startdump="$(date +%d.%m.%Y-%H%M)"
    logfile="$logdir"/"$logname"-"$startdump".log
    errorlog="$logdir"/"$logname"-"$startdump".err



# functions

    # failcheck: exit if fails
    failcheck () {
        if [[ $? = 0 ]] && [[ $failcount = 0 ]]; then
            echo -e "$yeah" | tee -a $logfile
        else
            echo -e "$shit \nENDE" | tee -a $logfile $errorlog
            exitwitherror             
        fi
    }

    # exit with errors or failure
    exitwitherror () {
        # unset maintenance mode
            sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
        # logfile entry
            echo -e "\nDump ist fehlgeschlagen und wurde abgebrochen\n\n" | tee -a $logfile $errorlog
        # set markerfile
            cp $logfile "$logdir"/last-error.log
        # send email
            (cat $errorlog; uuencode $logfile logfile.txt) | mail -s "Dump fehlgeschlagen: $server bei $site" $sendto
    ###        exit 1

    }

    # delete old logfiles
    logretention () {
        logpattern="*.log"
        ls -t $logdir/$logpattern | tail -n +$((keep + 1)) | xargs rm --
    }



# start logging
    if [[ ! -d $logdir ]]; then mkdir -p $logdir; fi
    touch "$scriptpath"/lastdump-start
    echo -e $headline \\n\
         \\b"Ausgeführt von $scriptpath/$scriptname" \\n\
         \\b"Dump gestartet $(date +%d.%m.%y-%H:%M)" \\n\
         > "$logfile"


# test writeable $dump_to
    touch $dump_to/testfile 2> >(tee $errorlog)
    if [[ $? = 0 ]]; then
        yeah="OK: Schreibtest auf Dump-Ziel erfolgreich"
        shit="FAIL: Kann im Dump-Ziel nichts löschen."
        rm $dump_to/testfile; failcheck
    else
        failcount=1
        shit="FAIL: Schreibtest auf Dump-Ziel fehlgeschlagen"
        failcheck
    fi


# set maintenance mode

    yeah="OK: Maintenance-Mode aktiviert"
    shit="FEHLER: Kann Maintenance-Mode nicht aktivieren."
    sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on; failcheck

# dump database

    mv "$dump_to"/"$db_dumpfile" "$dump_to"/"$db_dumpfile"1
    
    yeah="OK: Datenbank-Dump erfolgreich abgeschlossen"
    shit="FEHLER: Fehler beim Ausführen des Datenbank-Dumps"
    mysqldump --single-transaction -u "$db_user" -p"$db_pwd" "$db_name" > "$dump_to"/"$db_dumpfile"; failcheck

# unset maintenance mode

    yeah="OK: Maintenance-Mode wieder deaktiviert"
    shit="FEHLER: Kann Maintenance-Mode nicht deaktivieren."
    sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off; failcheck

# the end
    
    cp "$logfile" "$logdir"/last-success.log
    touch $dump_to/last-success
    touch "$scriptpath"/lastdump-stop
    if [ ! -s "$errorlog" ]; then rm "$errorlog"; fi   # delete $errorlog, when empty
    logretention