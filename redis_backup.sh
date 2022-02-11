#!/bin/bash
REDISCLI="/usr/local/redis6/master6389/redis-cli  -h $1 -p $3 -a $4"
LOGFILE="/etc/keepalived/scripts/keepalived.log"
echo "[BACKUP]" >> $LOGFILE
date >> $LOGFILE
echo "Being slave...." >> $LOGFILE 2>&1
echo "Run SLAVEOF cmd ..." >> $LOGFILE 2>&1
$REDISCLI SLAVEOF $2 $3 >> $LOGFILE
sleep 100                                             #延迟100秒以后待数据同步完成后再取消同步状态
exit(0)