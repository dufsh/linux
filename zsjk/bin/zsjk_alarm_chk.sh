#!/bin/bash
#Whritted: dufs
#E-mail:   fengshan.du@zznode.com
#Date:     2017-10-27 12:00

export LANG=en_US.UTF-8

SH_NAME=`basename $0`
SH_HOME=$HOME/zsjk

$SH_HOME/bin/zsjkAlarmIsert.sh "短信接口定期检测,3,【集中故障】【短信接口定期检测】0、8、12、16、20点收到此短信说明接口正常，巡检时间：`date '+%Y-%m-%d %T'`。,10.102.52.9,zsjk/bin/zsjk_alarm_test.sh"
