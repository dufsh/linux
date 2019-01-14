#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-09-19 13:00

#disk check

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

diskThrd=85

outlog  =============================================================
outlog  start check

sysapp="【集中故障】"
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
        sshTmp=$SH_HOME/data/df_k.$Local_IP.$ssh_port

        ssh -t -p $ssh_port $chk_user@$Local_IP "uname;df -k|grep -v /mnt" >$sshTmp
        rowNum=`cat $sshTmp|wc -l`
        
        if [ $rowNum -eq 0 ]
        then
             outlog can not get 'df -k' from $Local_IP:$ssh_port, please check !!!
             curT=`date '+%Y-%m-%d %T'`
             msg="$sysapp$curT获取$Local_IP:$ssh_port的df -k信息失败，请检查。"
        else
             nameOs=`cat $sshTmp|head -1`
             nameOS=${nameOs:0:3}
             #outlog OSname $nameOS
             
             if [ "$nameOS" = "Lin" -o "$nameOS" = "AIX" ]
             then
               diskUsed=`cat $sshTmp|grep [0-9]%| awk '{for(i=1;i<=NF;i++)if($i~/^[0-9]+%/)print $i}'|sed 's/\%//g'|sort -nk1|tail -1`
              #diskPath=`cat $sshTmp|grep $diskUsed%|cut -d" " -f2-|awk '{for(i=1;i<=NF;i++)if($i~/^\//)print $i}'|tr -d '\n'|sed 's//、/g'|sed 's/.$//g'`
               cat $sshTmp|grep $diskUsed%|cut -d" " -f2-|awk '{for(i=1;i<=NF;i++)if($i~/^\//)print $i}'>$sshTmp.tmp
               diskPath=`cat $sshTmp.tmp|sed 's/\n/,/g'`
               echo $diskPath
             else
                  outlog OS is not support , please contact fengshan.du@zznode.com
                  continue
             fi
						             
	     if [ $diskUsed -gt $diskThrd ]
	     then
		    outlog "$Local_IP:$ssh_port max disk used is $diskUsed % ,path is $diskPath , > $diskThrd %, please check!!!"
                    msg="$sysapp$Local_IP:$ssh_port磁盘空间使用率为$diskUsed %，大于$diskThrd %，，目录为$diskPath，请检查，巡检时间：`date '+%Y-%m-%d_%T'`"
	     else
		    outlog "$Local_IP:$ssh_port max disk used is $diskUsed % , path is $diskPath ,< $diskThrd % it is OK."
             fi
						
        fi

        if [ "$msg" != "" ]
        then
             outlog send message $msg

             #---变量里有特殊符号/，直接sed替换报错
             sendFile=disk_chk_$Local_IP.$ssh_port.sql
             cat $msgTemp1 >$SH_HOME/bin/$sendFile
             echo "'"$msg"'" >>$SH_HOME/bin/$sendFile
             cat $msgTemp2 >>$SH_HOME/bin/$sendFile
             
             sed -e "s/__SHELL__/$SH_NAME/g" $sendFile >$sendFile"_N"
             mv $sendFile"_N" $sendFile
             outlog `./sendMsg.sh $sendFile`

             cd $SH_HOME/pyChk/
             python Demo_sms.pyo 13730885681 "$msg"

             rm $SH_HOME/bin/$sendFile
        fi
						
        outlog -------------------------------------------------------------
done    
outlog  =============================================================
exit 0
