#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-09-19 13:00

# excute remote cmd


SH_NAME=`basename $0`
SH_HOME=$HOME/zsjk
SH_Log=$SH_HOME/log/${0%\.sh*}.log


function outlog {
                    echo $*
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

if [ $# -ge 1 ]
then
    cmd=$1
else
    outlog need cmd, usage $0 cmd
    exit -1
fi

outlog  start excute cmd $cmd


ip_list=$SH_HOME/conf/hostchk.conf

if [ ! -f $ip_list ]
then
     outlog can not find $ip_list, please check !!!
     exit 0
fi

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

        outlog read config: Local_IP $Local_IP ssh_port $ssh_port chk_user $chk_user
        
        sshTmp=$SH_HOME/data/$SH_NAME.$Local_IP.$ssh_port

        ssh -t -p $ssh_port $chk_user@$Local_IP "$cmd">$sshTmp
        
        while read line
        do
            outlog $line
        done < $sshTmp

done    
outlog  =============================================================
exit 0
