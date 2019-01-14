#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-09-19 13:00

#cpu、memory check

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
MemThrd=3
CpuThrd=30

msgTemp1=$SH_HOME/conf/sendmsg_temp_begin.sql
msgTemp2=$SH_HOME/conf/sendmsg_temp_end.sql

if [ ! -f $msgTemp1 -o ! -f $msgTemp2 ]
then
     outlog can not find $msgTemp1 or $$msgTemp2, please check !!!
     exit 0
fi

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

        sshTmp=$SH_HOME/data/vmstat.$Local_IP.$ssh_port
        ssh -t -p $ssh_port $chk_user@$Local_IP "uname;vmstat 2 5" >$sshTmp
        rowNum=`cat $sshTmp|wc -l`
        
        if [ $rowNum -eq 0 ]
        then
             outlog can not get 'vmstat' from $Local_IP, please check !!!

             curT=`date '+%Y-%m-%d %T'`
             msg="$sysapp获取$Local_IP:$ssh_port的vmstat信息失败"
             msgFlg=1
        else
             nameOs=`cat $sshTmp|head -1`
             nameOS=${nameOs:0:3}
             #outlog OSname $nameOS
             
             if [ "$nameOS" = "Lin" ]
             then
                 freeMem=`cat $sshTmp|tail -1|awk '{print $4}'`
                 idleCpu=`cat $sshTmp|tail -3|awk '{print $15}'|awk '{sum+=$1} END {print int(sum/3)}'`
                 freeMemG=`echo "$freeMem/1024/1024"|bc`
             elif [ "$nameOS" = "AIX" ]
             then
                 freeMem=`cat $sshTmp|tail -1|awk '{print $4}'`
                 idleCpu=`cat $sshTmp|tail -3|awk '{print $16}'|awk '{sum+=$1} END {print int(sum/3)}'`
                 freeMemG=`echo "$freeMem/1024/1024"|bc`
             else
                 outlog OS is not support , please contact fengshan.du@zznode.com
                 continue
             fi
						             
	     if [ $freeMemG -lt $MemThrd ]
	     then
                    outlog "$Local_IP:$ssh_port freeMem = $freeMemG G, < $MemThrd G, please check!!!"

               #     if [ "$nameOS" = "Lin" ]
               #     then
               #          outlog try to clean caches .
               #          ssh -t -p $ssh_port root@$Local_IP "echo 3 > /proc/sys/vm/drop_caches;vmstat 1 3" $SH_HOME/data/vmstat.$Local_IP_N
               #          freeMem_N=`cat $SH_HOME/data/vmstat.$Local_IP_N|tail -1|awk '{print $4}'`
               #          freeMemG_N=`echo "$freeMem_N/1024/1024"|bc`
               #          outlog after clean caches $Local_IP freeMem = $freeMemG_N G .
               #     fi
                    msgFlg=1
                    msg="$sysapp$Local_IP:$ssh_port空闲内存为${freeMemG}G，小于${MemThrd}G"
	     else
		    outlog "$Local_IP:$ssh_port freeMem = $freeMemG G, > $MemThrd G, it is OK."
             fi
						
	     if [ $idleCpu -lt $CpuThrd ]
	     then
		    outlog "$Local_IP:$ssh_port idleCpu = $idleCpu % , < $CpuThrd %, please check!!!"
                    if [ $msgFlg -eq 0 ]
                    then
                          msgFlg=2
                          msg="$sysapp$Local_IP:$ssh_port空闲cpu为${idleCpu}%，小于${CpuThrd}%"
                    elif [ $msgFlg -eq 1 ]
                    then
                          msgFlg=12
                          msg="$msg，空闲cpu为${idleCpu}%，小于${CpuThrd}%"
                    fi

	     else
		    outlog "$Local_IP:$ssh_port idleCpu = $idleCpu % , > $CpuThrd %, it is OK."
	     fi
        fi
        
        if [ $msgFlg -gt 0 ]
        then
             msg="$msg，请尽快处理，巡检时间：`date '+%Y-%m-%d_%T'`"
             outlog send message $msg
             
             sendFile=cpu_mem_chk_$Local_IP.$ssh_port.sql
             cat $msgTemp1 >$sendFile
             echo "'"$msg"'" >>$sendFile
             cat $msgTemp2 >>$sendFile

             sed -e "s/__SHELL__/$SH_NAME/g" $sendFile >$sendFile"_N"
             mv $sendFile"_N" $sendFile
             outlog `./sendMsg.sh $sendFile`

             rm $SH_HOME/bin/cpu_mem_chk_$Local_IP.*
        fi

        outlog -------------------------------------------------------------
done    
outlog  =============================================================
exit 0
