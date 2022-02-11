#!/bin/bash
REDISCLI="/usr/local/redis6/master6389/redis-cli -h $1 -p $3 -a $4"
LOGFILE="/etc/keepalived/scripts/keepalived.log"
echo "[master]" >> $LOGFILE
date >> $LOGFILE
echo "Being master...." >> $LOGFILE 2>&1
echo "Run SLAVEOF cmd ... " >> $LOGFILE
$REDISCLI SLAVEOF $2 $3 >> $LOGFILE  2>&1
 
#echo "SLAVEOF $2 cmd can't excute ... " >> $LOGFILE
sleep 10                                               #延迟10秒以后待数据同步完成后再取消同步状态
echo "Run SLAVEOF NO ONE cmd ..." >> $LOGFILE
$REDISCLI SLAVEOF NO ONE >> $LOGFILE 2>&1