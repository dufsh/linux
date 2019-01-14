#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-09-19 13:00

#ping check
#  ping输出有如下两种结果，有时候会有duplicates输出
#
#  10 packets transmitted, 10 received, +1 duplicates, 0% packet loss, time 9001ms rtt min/avg/max/mdev = 0.432/6.303/32.608/12.369 ms
#  10 packets transmitted, 10 received, 0% packet loss, time 9000ms rtt min/avg/max/mdev = 0.418/0.466/0.500/0.032 ms
#

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

sysapp="【集中故障】"
msgTemp=$SH_HOME/conf/sendmsg_temp.sql
if [ ! -f $msgTemp ]
then
     outlog can not find $msgTemp, please check !!!
     exit 0
fi


ip_list=$SH_HOME/conf/pingChk.conf

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

        outlog read config: Local_IP $Local_IP

        ping $Local_IP -c 10 -s 1024 >$SH_HOME/data/ping.$Local_IP
        outlog `cat $SH_HOME/data/ping.$Local_IP |tail -2`
        dupCnt=`tail -2 $SH_HOME/data/ping.$Local_IP| head -1|grep -c duplicates`
        if [ $dupCnt -eq 1 ]
        then
             dupNum=`tail -2 $SH_HOME/data/ping.$Local_IP| head -1|awk '{print $6}'||sed 's/\+//g'`
             pkgLos=`tail -2 $SH_HOME/data/ping.$Local_IP| head -1|awk '{print $8}'|sed 's/\%//g'`
        else
             pkgLos=`tail -2 $SH_HOME/data/ping.$Local_IP| head -1|awk '{print $6}'|sed 's/\%//g'`
        fi
        
        if [ $pkgLos -gt 0 ]
        then
            outlog ping $Local_IP packet loss is $pkgLos % , please check !!!  
            curT=`date '+%Y-%m-%d %T'`
            msg="$sysapp$curT ping $Local_IP packet loss $pkgLos %，请检查。"
            sed -e "s/__MSG__/$msg/g" \
                -e "s/__SHELL__/$SH_NAME/g"    $msgTemp > $SH_HOME/bin/ping_chk_$Local_IP.sql
            outlog `./sendMsg.sh ping_chk_$Local_IP.sql`
            cd $SH_HOME/pyChk/
            python Demo_sms.pyo 13730885681 "$msg"

            rm $SH_HOME/bin/ping_chk_$Local_IP.sql
        fi
        outlog -------------------------------------------------------------
done    
outlog  =============================================================
exit 0
