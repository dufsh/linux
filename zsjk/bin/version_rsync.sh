#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-10-18 14:00

#vension rsyn

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
outlog  start sync

ip_list=$SH_HOME/conf/version_rsync.conf

if [ ! -f $ip_list ]
then
     outlog can not find $ip_list, please check !!!
     exit 0
fi

sess=`date +'%y%m%d%h%M'`

cd $SH_HOME/bin

for  line in `cat $ip_list`
do
        sharppos=$(echo $line|awk '{print index($1,"#")}')

        if [ $sharppos = 1 ]
        then
            #echo remarked line,ignore
            continue
        fi

        outlog -------------------------------------------------------------   
        Local_IP=`echo $line | awk -F"," '{print $1}'`
        chk_user=`echo $line | awk -F"," '{print $2}'`
        ssh_port=`echo $line | awk -F"," '{print $3}'`

        outlog read config: Local_IP $Local_IP
        #outlog read config: chk_user $chk_user
        #outlog read config: ssh_port $ssh_port

        remote_cmd="cd /home/iss/rsync_client;./rsyncd_52.10.sh"
        ssh -t -p $ssh_port $chk_user@$Local_IP "$remote_cmd" >$SH_HOME/data/version_rsync.$Local_IP
        
        outlog -------------------------------------------------------------
done    

outlog  =============================================================
