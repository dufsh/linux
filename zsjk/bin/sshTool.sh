#!/bin/bash

usage()
{
   echo "Usage: `basename $0` hostip user passwd port command "
   exit 0
}

argvNum=5

if [ $# -ge $argvNum ]
then
    hostip=$1
    port=$2
    user=$3
    passwd=$4
    command=$5

    echo hostip = $hostip
    echo user = $user
    echo passwd = $passwd
    echo port = $port
    echo command= $command
else
     echo argv less then $argvNum
     usage
     exit -1
fi


/usr/bin/expect  <<EOF
set timeout 65
spawn ssh -t -p $port $user@$hostip
expect {
  "(yes/no)?" {send "yes\r"; expect_continue}
  "$user@$hostip's password: " {send "$passwd\r"}
  "ssh: connect to host $hostip port $port: Connection refused" exit
  "Couldn't read packet: Connection reset by peer" exit
  "bash*" {send "ls -lrt 3\r"}
  "$hostip*]"    {send "ls -lrt 3\r"}
}

expect {
   "$user@$hostip's password: " exit
   "*bash*" {send "$command \r" }
   "$hostip*]" {send "$command \r" }
}
expect {
   "*bash*" exit
   "$hostip*]"     exit
}

expect eof exit

EOF
