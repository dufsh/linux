#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2017-03-04 12:00

#queue depth check

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

sysapp="【MQ队列监测】"
DepThrd=10000
msg=""

ip_list=$SH_HOME/conf/depthChk.conf

if [ ! -f $ip_list ]
then
     outlog can not find $ip_list, please check !!!
     exit 0
fi

cd $SH_HOME/

for  line in `cat $ip_list`
do

        sharppos=$(echo $line|awk '{print index($1,"#")}')

        if [ $sharppos = 1 ]
        then
            #echo remarked line,ignore
            continue
        fi

        outlog -------------------------------------------------------------   
        mqsc=`echo $line | awk -F"," '{print $1}'`
        queName=`echo $line | awk -F"," '{print $2}'`

        outlog read config: mqsc $mqsc
        outlog read config: queue $queName
        
        Depth=`echo "DISPLAY QLOCAL($queName)"|runmqsc $mqsc|grep CURDEPTH|awk -F'[()]' '{print $2}'`

        #echo $Depth
        
        if [ "$Depth" = "" ]
        then
             outlog $mqsc $queName depth not get , please check !!!
             msg=$msg" $mqsc $queName：未获取到队列深度"

        elif [ $Depth -gt $DepThrd ]
        then
             outlog $mqsc $queName depth is $Depth , more than $DepThrd please check !!!
             msg="$mqsc $queName：$Depth"
        else
             outlog $mqsc $queName depth is $Depth , less than $DepThrd ,it is ok.
        fi
        outlog -------------------------------------------------------------
done
        
if [ "$msg" != "" ]
then
        Date=`date '+%Y%m%d%H%M%S'`
        msg=$sysapp"监测到以下队列异常：$msg，请尽快处理，巡检时间：`date '+%Y-%m-%d %T'`"
        outlog send message $msg
             
        sendFile=$SH_NAME.$Date
        echo $msg >$sendFile
        #outlog `./sendMsg.sh $sendFile`
        outlog `./sendMsg.sh $sendFile tnms2 tn15ms! 10.101.129.8 applications/bin/zsjk/data/`
        rm $sendFile
fi

outlog  =============================================================
exit 0
