#!/bin/bash

function zsjkAlarmIsert()
{
		if [ $# -lt 1 ]
		then 
		     echo failed .
		     usage
		fi 

		insertSql="insert into zsjk_alarm(alarm_id,alarm_type,alarm_level,alarm_text,monitor_server,monitor_task) values (zsjk_alarm_id_seq.nextval,:x1,:x2,:x3,:x4,:x5)"
		insertArg="$*"
		cd $HOME/zsjk/pyChk/
		python2.7 execInsertSql.py "$insertSql" "$insertArg"
}

usage()
{
   echo "Usage: `basename $0` argList"
   exit 0
}

zsjkAlarmIsert $*