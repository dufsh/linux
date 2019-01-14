#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-08-25 11:00

#ip switch check

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

msgTemp=$SH_HOME/conf/sendmsg_temp.sql
if [ ! -f $msgTemp ]
then
     outlog can not find $msgTemp, please check !!!
     exit 0
fi

ip_list=$SH_HOME/conf/ip_swich_chk.conf
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
        Virtu_IP=`echo $line | awk -F"," '{print $2}'`
        chk_user=`echo $line | awk -F"," '{print $3}'`
        ssh_port=`echo $line | awk -F"," '{print $4}'`

        outlog Local_IP $Local_IP
       #outlog read config: Virtu_IP $Virtu_IP
       #outlog read config: chk_user $chk_user
       #outlog read config: ssh_port $ssh_port

        ssh -t -p $ssh_port $chk_user@$Local_IP "/sbin/ip add" >$SH_HOME/data/ipadd.$Local_IP
        rowNum=`cat $SH_HOME/data/ipadd.$Local_IP|wc -l`
        
        if [ $rowNum -eq 0 ]
        then
             outlog can not get '/sbin/ip add' from $Local_IP, please check !!!
             cat /dev/null>$SH_HOME/data/Last_ipadd.$Local_IP

             curT=`date '+%Y-%m-%d %T'`
             msg="【浮动IP切换】$curT获取$Local_IP的IP地址信息失败，请检查。"
             sed -e "s/__MSG__/$msg/g" \
                 -e "s/__SHELL__/$SH_NAME/g"    $msgTemp > $SH_HOME/bin/ip_swich.$Local_IP.sql
             outlog `./sendMsg.sh ip_swich.$Local_IP.sql`

             rm $SH_HOME/bin/ip_swich.$Local_IP.sql
             continue
        else
             Vip=`cat $SH_HOME/data/ipadd.$Local_IP|grep "scope global secondary"|awk '{print $2}'|awk -F"/" '{print $1}'`
             #outlog local ip : $Local_IP

             outlog this flow ip : $Vip
             #get last flow ip

             if [ -f $SH_HOME/data/Last_ipadd.$Local_IP ]
             then 
                   Vip_last=`cat $SH_HOME/data/Last_ipadd.$Local_IP`
             else
                   Vip_last=""
             fi
    
             outlog last flow ip : $Vip_last

             Vip_chg=0
             Vip_run=0

             if [ "$Vip_last" != "$Vip" ]
             then
                 Vip_chg=1
             fi
             if [ "$Virtu_IP" = "$Vip" ]
             then
                 Vip_run=1
             fi

             if [ $Vip_chg -eq 0 -a $Vip_run -eq 0 ]
             then
                  outlog Virtu_IP $Virtu_IP not running on server $Local_IP.
             fi
             if [ $Vip_chg -eq 1 -a $Vip_run -eq 0 ]
             then
                  outlog switched !!!
                  outlog Virtu_IP $Vip_last switch to other server from server $Local_IP.
                  curT=`date '+%Y-%m-%d %T'`
                  msg="【浮动IP切换】$curT监测到浮动IP $Vip_last从$Local_IP切换到了其它服务器，请检查。"
                  oulog send message $msg
                  #echo $msg > $SH_HOME/bin/ip_swich.$Local_IP.txt
                  #outlog `sendMsg.sh ip_swich.$Local_IP tnms2 tn15ms! 10.101.129.8 /home/tnms2/applications/bin/zsjk/data/`
                  
                  sed -e "s/__MSG__/$msg/g" \
                        -e "s/__SHELL__/$SH_NAME/g"    $msgTemp > $SH_HOME/bin/ip_swich.$Local_IP.sql
                  outlog `./sendMsg.sh ip_swich.$Local_IP.sql`
                  rm $SH_HOME/bin/ip_swich.$Local_IP.sql
             fi
             if [ $Vip_chg -eq 0 -a $Vip_run -eq 1 ]
             then
                  outlog Virtu_IP $Vip runing on server $Local_IP.
             fi
             if [ $Vip_chg -eq 1 -a $Vip_run -eq 1 ]
             then
                  outlog switched !!!
                  outlog flow ip $Vip switch from other server to server $Local_IP.
                  curT=`date '+%Y-%m-%d %T'`
                  msg="【浮动IP切换】$curT监测到浮动IP $Vip切换到了服务器$Local_IP，请检查。"
                  outlog send message $msg
                  #echo $msg > $SH_HOME/bin/ip_swich.$Local_IP.txt
                  #outlog `./sendMsg.sh ip_swich.$Local_IP tnms2 tn15ms! 10.101.129.8 /home/tnms2/applications/bin/zsjk/data/`

                  sed -e "s/__MSG__/$msg/g" \
                      -e "s/__SHELL__/$SH_NAME/g"    $msgTemp > $SH_HOME/bin/ip_swich.$Local_IP.sql
                  outlog `./sendMsg.sh ip_swich.$Local_IP.sql`
                  rm $SH_HOME/bin/ip_swich.$Local_IP.sql
             fi
             echo $Vip >$SH_HOME/data/Last_ipadd.$Local_IP
         fi
        outlog -------------------------------------------------------------

done    

outlog  =============================================================
exit 0
