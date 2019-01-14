#!/usr/bin/bash
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2017-02-28 15:50
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

ip_list=$SH_HOME/conf/hostchk.conf

if [ ! -f $ip_list ]
then
     outlog can not find $ip_list, please check !!!
     exit 0
fi

cd $SH_HOME/bin

for  line in `cat $ip_list`
do
        msg=""
        msgFlg=0
        # msgFlg: 0 no message, 1 mem ,2 cpu ,12 mem and cpu

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
        outlog read config: ssh_port $ssh_port

        sshTmp=$SH_HOME/data/lsof_ps.$Local_IP.$ssh_port
        ssh -t -p $ssh_port $chk_user@$Local_IP "/usr/sbin/lsof -i :1521|grep java;ps -fu $chk_user" >$sshTmp
        rowNum=`cat $sshTmp|wc -l`
        
        if [ $rowNum -eq 0 ]
        then
             outlog can not get 'vmstat' from $Local_IP, please check !!!
        else
             lsofTmp=$SH_HOME/data/lsof.$Local_IP.$ssh_port
        	   cat $sshTmp|egrep "^java"|awk '{print $2}'|sort|uniq -c|sort -rnk1>$lsofTmp
        		 
             while read line
             do
                 num=`echo $line |awk '{print $1}'`
                 pid=`echo $line |awk '{print $2}'`
                 psName=`cat $sshTmp|grep -v "^java"|grep -w $pid|grep -v grep |grep "java -D"|awk -F"java " '{print $2}'|awk '{print $1}'|sed 's/\-D/D/g'`
                 outlog pid = $pid  dbcount = $num  psName = $psName
             done < $lsofTmp
             
        fi
        outlog -------------------------------------------------------------
done
outlog  =============================================================
exit 0