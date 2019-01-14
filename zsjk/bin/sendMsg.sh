#!/bin/bash

sendMsg()
{

#第一个参数是文件名

IP=10.101.211.4
USERNAME=oracle
PASSWORD=Zog,Ge*180Kg
RemPath=/backup/zsjk/data

if [ $# -lt 1 ]
then 
     echo failed .
     usage
fi 

if [ ! -f $1 ]
then
     echo  failed . can not find file $1,please check !!!
     exit 1
fi

sedFile=$1

if [ $# -eq 5 ]
then
     USERNAME=$2
     PASSWORD=$3
     IP=$4
     RemPath=$5
fi

sess=`date '+%Y%m%d%H%M'`

ftp -v -n<< EOF  >/dev/null
open $IP
user $USERNAME $PASSWORD
binary
prompt off
cd $RemPath
put $sedFile
ls -lrt ftpFile.list.$sess
close
bye

EOF

FileNum=`cat ftpFile.list.$sess|grep $sedFile|wc -l`
rm -rf ftpFile.list.$sess

if [ $FileNum -eq 0 ]
then
     echo ftp to $IP failed .
else
     echo ftp to $IP successed .
fi

}

usage()
{
   echo "Usage: `basename $0` filename [ user passwd ip path ]"
   echo ""
   echo "Options:"
   echo "   filename : sql file [ default 10.101.211.4 /backup/zsjk/data ]"
   echo "       exp . $0 wsmonitor.log"
   echo "       exp . $0 wsmonitor.log ftps Zhjk_123 10.101.58.42 /export/home/ftps/pf/"
   exit 0
}

sendMsg $*
