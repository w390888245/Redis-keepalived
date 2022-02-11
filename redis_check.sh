#!/bin/bash
ALIVE=`/usr/local/redis6/master6389/redis-cli -h $1 -p $2 -a $3 PING`
LOGFILE="/etc/keepalived/scripts/keepalived.log"
echo "[CHECK]" >> $LOGFILE
date >> $LOGFILE
if [ $ALIVE == "PONG" ]; then :
    echo "Success:redis-cli -h $1 -p $2 PING $ALIVE" >> $LOGFILE 2>&1
    exit 0
else
    echo "Failed:redis-cli -h $1 -p $2 PING $ALIVE " >> $LOGFILE 2>&1
    exit 1
fi