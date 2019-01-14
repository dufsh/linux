#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-09-19 13:00

# process memory check
# config file : conf/procMemChk.conf  proc_Key,proc_Log,mem_Thrd
# process running server  conf/ps_info_cur.txt  exp. 10.102.52.13_22444,DFmSocketServer DCASServer DAlarmForwordServer DSECServer DWebService DWebUIServer
#


SH_NAME=`basename $0`
SH_HOME=$HOME/zsjk
SH_Log=$SH_HOME/log/${0%\.sh*}.log

function outlog {
                    #echo $*
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

ip_list=$SH_HOME/conf/procMemChk.conf

if [ ! -f $ip_list ]
then
     outlog can not find $ip_list, please check !!!
     exit 0
fi

ps_serv=$SH_HOME/conf/ps_info_cur.txt

if [ ! -f $ps_serv ]
then
     outlog can not find $ps_serv, please check !!!
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
        proc_Key=`echo $line | awk -F"," '{print $1}'`
        proc_Log=`echo $line | awk -F"," '{print $2}'`
        mem_Thrd=`echo $line | awk -F"," '{print $3}'`

        outlog read config: proc_Key $proc_Key , proc_Log $proc_Log , mem_Thrd $mem_Thrd
        
        ipPorts=`grep -w $proc_Key $ps_serv|awk -F"," '{print $1}'`
        for Line in `echo $ipPorts`
        do
            Local_IP=`echo $Line|awk -F"_" '{print $1}'`
            ssh_port=`echo $Line|awk -F"_" '{print $2}'`
            chk_user="iss"
            outlog $proc_Key is running on $Local_IP:$ssh_port $chk_user
            
            sshTmp=$SH_HOME/data/procMemChk_$proc_Key.$Local_IP.$ssh_port
            ssh -t -p $ssh_port $chk_user@$Local_IP "cd ISS_LOG;tail -200 $proc_Log|grep 'Current memory'|tail -1;tail -200 $proc_Log|grep 'Free memory'|tail -1" >$sshTmp
            
            rowNum=`cat $sshTmp|wc -l`
        
            if [ $rowNum -eq 0 ]
            then
                 outlog can not get $proc_Key info from $Local_IP, please check !!!

                 curT=`date '+%Y-%m-%d %T'`
                 msg="$sysapp从$Local_IP:$ssh_port未获取到 $proc_Key 的内存信息，请检查。"
                 msgFlg=1
            else
                 TimeStp=`cat $sshTmp|grep 'Current memory'|tr -d '\r'|sed -s 's///g'|awk -F"." '{print $1}'`            
                 usedMem=`cat $sshTmp|grep 'Current memory'|tr -d '\r'|sed -s 's///g'|awk -F":" '{print $4}'`
                 isFree=`cat $sshTmp|grep 'Free memory'|tr -d '\r'|sed -s 's/^M//g'|wc -l`
                 #echo $isFree
                 if [ $isFree -ge 1 ]
                 then
                     TimeStpF=`cat $sshTmp|grep 'Free memory'|tr -d '\r'|sed -s 's///g'|awk -F"." '{print $1}'`            
                     freeMem=`cat $sshTmp|grep 'Free memory'|tr -d '\r'|sed -s 's///g'|awk -F":" '{print $4}'`
                 else
                     TimeStpF=$TimeStp
                     freeMem=0
                 fi

                 #echo $usedMem $TimeStp
                 #echo $freeMem $TimeStpF
                 if [ "$TimeStp" = "$TimeStpF" ]
                 then
                     usedMemF=`echo "$usedMem-$freeMem"|bc`
                 fi
                 #echo $usedMemF

                 if [ $usedMemF -ge $mem_Thrd ]
                 then
                      outlog "$Local_IP:$ssh_port $proc_Key usedMem = $usedMem K, freeMem = $freeMem K, larger then $mem_Thrd K, please check!!!"
                      msgFlg=1
                      msg="$sysapp从$Local_IP:$ssh_port获取到$proc_Key的内存为${usedMem}K（日志时间：$TimeStp），大于门限${mem_Thrd}K，请检查。"
                 else
                      outlog "$Local_IP:$ssh_port $proc_Key usedMem = $usedMem K, freeMem = $freeMem K, less then $mem_Thrd K, it is OK."
                 fi
            fi
            
            if [ $msgFlg -gt 0 ]
            then
                 msg="$msg巡检时间：`date '+%Y-%m-%d %T'`"
                 outlog send message $msg
                 $SH_HOME/bin/zsjkAlarmIsert.sh "进程内存监测,1,$msg,10.102.52.9,zsjk/bin/procMemChk.sh"

                 #send restart info to running server.
                 echo "`date +'%Y-%m-%d %T'` usedMem = $usedMem K"  >${proc_Key}.restart
                 scp -P$ssh_port ${proc_Key}.restart $chk_user@$Local_IP:./zsjk/restartflag/
            fi
             
        done

        outlog -------------------------------------------------------------
done    
outlog  =============================================================
exit 0
