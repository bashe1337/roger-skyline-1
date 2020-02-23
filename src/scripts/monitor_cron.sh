#!bin/sh
MSG="/etc/crontab has been modified!"
SUBJECT="Monitor changes crontab"
ROOT="root@localhost"
HASH="/etc/cron.d/hash"
FILE="/etc/crontab"
CH_FILE="/etc/cron.d/cron_hash_md5"
test -f $HASH || sudo touch $HASH
CRON_HASH=$(sudo md5sum $FILE)
sudo touch $CH_FILE
sudo echo $CRON_HASH > $CH_FILE
if [ "$(cat $HASH)" != "$(cat $CH_FILE)" ]; then
	echo $CRON_HASH > $HASH
	echo $MSG | mail -s "$SUBJECT" $ROOT
fi;
exit
