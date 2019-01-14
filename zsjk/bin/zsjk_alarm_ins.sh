#!/bin/bash
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2017-10-24 12:00

SH_NAME=`basename $0`
SH_HOME=$HOME/zsjk
SH_Log=$SH_HOME/log/${0%\.sh*}.log

function outlog {
                    echo "`date '+%Y-%m-%d %T'` : " "$*" >>  $SH_Log
                    logSize=`ls -lrt $SH_Log|awk '{print $5}'`
                    if [ $logSize -gt 10240000 ]
                    then
                         cp -rp $SH_Log $SH_Log.`date '+%Y-%m-%d'`
                         gzip $SH_Log.`date '+%Y-%m-%d'`
                         cat /dev/null>$SH_Log
                    fi
                }

outlog  =============================================================
outlog  start check

fileConf=$SH_HOME/conf/zsjkSendFile.conf
if [ ! -f $fileConf ]
then
     outlog can not find $fileConf, please check !!!
     exit -1
fi

cd  $SH_HOME/bin/SendMsgData
num=`ls -lrt |grep txt|wc -l`
if [ $num -gt 0 ]
then
  for file in `ls *.txt`
  do
     outlog get new $file
     sendMsg=`cat $file`

     ifConf=`cat $fileConf|grep -w $file|wc -l`
     if [ $ifConf -eq 0 ]
     then
          outlog not get config info for $file,use null
          alarm_type='noConfig'
          alarm_level=4
          monitor_server='noConfig'
          monitor_task='noConfig'
     else
          alarm_type=`cat $fileConf|grep -w $file|awk -F"," '{print $2}'`
          alarm_level=`cat $fileConf|grep -w $file|awk -F"," '{print $3}'`
          monitor_server=`cat $fileConf|grep -w $file|awk -F"," '{print $4}'`
          monitor_task=`cat $fileConf|grep -w $file|awk -F"," '{print $5}'`
     fi
     
     $HOME/zsjk/bin/zsjkAlarmIsert.sh "$alarm_type,$alarm_level,$sendMsg,$monitor_server,$monitor_task"

     rm $file
  done
fi

