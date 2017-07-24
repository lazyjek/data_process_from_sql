#!/bin/bash
source writeSQL.conf
source sql_functions.sh

####################
# @ data prepare
work_dir=$(cd `dirname $0`; pwd)
root_dir=$(dirname ${work_dir})
logFile=${root_dir}/log/update.log
date=`date +%Y-%m-%d`
data="${root_dir}/output/score"
if [ $# -ne 0 ];then
	data=$1
fi

if [ ! -s $logFile ];then
	echo "$date `date +%H:%M:%S`" > $logFile
fi

######################
# @ update table1
echo "$date `date +%H:%M:%S` : update table BEGIN" >> ${logFile}
update_table ${SCHEMA1} ${TABLE1} ${data}
if [ $? -ne 0 ];then
	echo "$date `date +%H:%M:%S` update table fail !" >> $logFile
	exit 1
fi
echo "$date `date +%H:%M:%S` : update table SUCC" >> ${logFile}
#####################
echo "$date `date +%H:%M:%S` : STEP UPDATE DATABASE COMPLETED" >> ${logFile}
