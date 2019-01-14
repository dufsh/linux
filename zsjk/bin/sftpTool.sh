#!/bin/bash

usage()
{
   echo "Usage: `basename $0` hostip user passwd port list|put|get remotePath localPath file "
   echo "exp :  `basename $0`  hostip user passwd port list remotePath [file]"
   echo "exp :  `basename $0`  hostip user passwd port put remotePath localPath file"
   echo "exp :  `basename $0`  hostip user passwd port get remotePath localPath file"
   exit 0
}

argvNum=6

if [ $# -ge $argvNum ]
then
    hostip=$1
    user=$2
    passwd=$3
    port=$4
    RemotePath=$6
    #localPath=$7
    #file=$8

    case $5 in
           "list")      oper="ls -lrt"                    ;;
           "put"|"get") oper=$5                           ;;
           *|\?)        usage                             ;;
    esac
    
    if [ $# -eq 6 -a "$oper" = "ls -lrt" ]
    then
         continue
    elif [ $# -ge 7 -a "$oper" = "ls -lrt" ]
    then 
         file=$7
         echo $file
    elif [ $# -ge 8 -a  "$oper" != "ls -lrt" ]
    then
         file=$8
         localPath=$7
    else
         usage
    fi

    echo hostip = $hostip
    echo user = $user
    echo passwd = $passwd
    echo port = $port
    echo RemotePath = $RemotePath
    echo localPath = $localPath
    echo file = $file
    echo oper = $oper
else
     echo argv less then $argvNum 
     usage
     exit -1
fi


/usr/bin/expect  <<EOF
set timeout 65 
spawn sftp -oPort=$port $user@$hostip 
expect {  
  "(yes/no)?" {send "yes\r"; expect_continue}  
  "$user@$hostip's password: " {send "$passwd\r"}  
  "ssh: connect to host $hostip port $port: Connection refused" exit
  "Couldn't read packet: Connection reset by peer" exit
  "Password:" {send "$passwd\r"}
  "sftp>" {send \r}
}  

expect {
   "$user@$hostip's password: " exit
   "sftp>" {send "cd $RemotePath\r" }
}

expect "sftp>" {send "lcd $localPath \r"}
expect "sftp>" {send "$oper $file \r"}
expect "sftp>" {send "bye \r"}
expect eof exit
EOF
