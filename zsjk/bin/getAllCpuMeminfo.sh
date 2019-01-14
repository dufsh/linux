#!/bin/bash 
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2016-09-19 13:00

#get cpuinfo

SH_HOME=$HOME/zsjk

ip_list=$SH_HOME/conf/hostchk.conf

if [ ! -f $ip_list ]
then
     echo can not find $ip_list, please check !!!
     exit 0
fi

mv cpuMeminfo.txt cpuMeminfo.bak`date +'%Y%m%d%H%M%S'`

echo collect time : `date +'%Y-%m-%d %T'` > cpuMeminfo.txt
echo "">>cpuMeminfo.txt

for  line in `cat $ip_list`
do
        sharppos=$(echo $line|awk '{print index($1,"#")}')

        if [ $sharppos = 1 ]
        then
            #echo remarked line,ignore
            continue
        fi

        Local_IP=`echo $line | awk -F"," '{print $1}'`
        chk_user=`echo $line | awk -F"," '{print $2}'`
        ssh_port=`echo $line | awk -F"," '{print $3}'`


        sshTmp1=$SH_HOME/data/cpuinfo.$Local_IP.$ssh_port

        ssh -t -p $ssh_port $chk_user@$Local_IP "uname ; cat /proc/cpuinfo|tail -27;cat /proc/meminfo|head -1" >$sshTmp1
        
        sed -e 's///g' $sshTmp1 > cpuinfo.tmp
        mv cpuinfo.tmp $sshTmp1
       
        nameOs=`cat $sshTmp1|head -1`
        nameOS=${nameOs:0:3} 
        #echo $nameOS
        if [ "$nameOS" != "Lin" ] 
        then
             continue
        fi

        cpumum=`cat $sshTmp1|grep processor|tail -1|awk -F":" '{print $2}'`
        pronum=`echo "$cpumum+1"|bc`
        memsize=`cat $sshTmp1|grep MemTotal|awk '{print $2,$3}'`

        echo  "$Local_IP:"               >>cpuMeminfo.txt
        echo ------------------------------------------------------- >>cpuMeminfo.txt
        echo "processor num   : $pronum" >>cpuMeminfo.txt
        cat $sshTmp1|grep "cpu cores"    >>cpuMeminfo.txt
        cat $sshTmp1|grep "model name"   >>cpuMeminfo.txt
        cat $sshTmp1|grep "cpu MHz"      >>cpuMeminfo.txt
        cat $sshTmp1|grep "cache size"   >>cpuMeminfo.txt
        echo ""                          >>cpuMeminfo.txt
        cat $sshTmp1|grep MemTotal       >>cpuMeminfo.txt
        echo ------------------------------------------------------- >>cpuMeminfo.txt
        echo ""                          >>cpuMeminfo.txt
        echo ""                          >>cpuMeminfo.txt
        

done    
