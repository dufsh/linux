#!/usr/bin/bash
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2018-02-24 15:50
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

        outlog read config: Local_IP $Local_IP ssh_port $ssh_port
        #outlog read config: chk_user $chk_user
        #outlog read config: ssh_port $ssh_port

        sshTmp=$SH_HOME/data/ulimit_lsof.$Local_IP.$ssh_port
        ssh -t -p $ssh_port $chk_user@$Local_IP "ulimit -n;/usr/sbin/lsof" >$sshTmp
        rowNum=`cat $sshTmp|wc -l`
        
        if [ $rowNum -eq 0 ]
        then
             outlog can not get 'ulimit' from $Local_IP, please check !!!
             msgFlg=1
             msg="$sysapp$curT获取$Local_IP的ulimit_lsof信息失败"

        else
             lsofTmp=$SH_HOME/data/ulimit_lsof_ps.$Local_IP.$ssh_port
             cat $sshTmp|grep -v 'open files'|sort -rnk 2|awk '{print $1,$2,$3}'|uniq -c|sort -rnk 1|head>$lsofTmp

             ulimit_thrd=1000        	   
             ulimit_n=`cat $sshTmp|head -1|awk '{print $1}'|sed -e 's///g'|tr -d '\n'`
             #echo $ulimit_n
             unum=`cat $sshTmp|head -1|grep unlimited|wc -l`
             if [ $unum -eq 1 ]
             then
                 ulimit_n="unlimited"
             else
                 if [ $ulimit_thrd -gt $ulimit_n ]
                 then 
                     ulimit_thrd=$ulimit_n
                 fi
             fi
        	  
             outlog $Local_IP:ssh_port $chk_user max open files is $ulimit_n.
        		 
             while read line
             do
                 num=`echo $line |awk '{print $1}'`
                 pkey=`echo $line |awk '{print $2}'`
                 pid=`echo $line |awk '{print $3}'`
                 puser=`echo $line |awk '{print $4}'`

                 outlog pid = $pid  count = $num  user = $puser  key = $pkey
                 if [ $num -ge $ulimit_thrd ]
                 then
                     outlog pid = $pid  count = $num  user = $puser  key = $pkey  open files more then $ulimit_thrd, please check !!!
                     msgFlg=1
                     msg=$msg" pid=$pid open files=$num user=$puser key=$pkey"
                 fi
             done < $lsofTmp
             
        fi
        
        if [ $msgFlg -eq 1 ]
        then
            msg="$sysapp$Local_IP:$ssh_port 打开文件数异常，$chk_user用户进程打开文件数量上限为$ulimit_n："$msg"，请尽快处理，巡检时间：`date '+%Y-%m-%d %T'`"
            $SH_HOME/bin/zsjkAlarmIsert.sh "进程监控,2,$msg,10.102.52.9,zsjk/bin/ulimit_n_chk.sh"
        fi
        
        outlog -------------------------------------------------------------
done
outlog  =============================================================
exit 0
