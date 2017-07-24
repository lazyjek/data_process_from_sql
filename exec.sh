#!/bin/bash
#############################
# @ data prepare
source ./env.conf
root_dir=$(cd `dirname $0`; pwd)
src_dir=${root_dir}/src
out_dir=${root_dir}/output
log_dir=${root_dir}/log
parse_data_dir=${root_dir}/parse_data
db_dir=${root_dir}/updateDB
job_log=${log_dir}/job_run_state.txt

date=`date +%Y%m%d`
if [ $1 ];then
	date=$1
fi
last_date=`date -d "-1 day ${date}" +%Y%m%d`
if [ `cat ${job_log} | grep -E "job_${last_date} is failed" | wc -l` -eq 1 ]
then
	date=${last_date}
fi
sql_date=`date -d "-3 day $date" +%Y%m%d`

job_detail=${log_dir}/job_run_state.${date}
del_job_detail=${log_dir}/job_run_state.${sql_date}
rm ${del_job_detail} -rf
if [ ! -s ${job_detail} ];then
	touch $job_detail
fi

function update_detail() {
	current_date=`date +%Y-%m-%d`
	current_hour=`date +%H:%M:%S`
	current_time=${current_date}" "${current_hour}
	current_date=$5
	logFile=$2
	detailFile=$3
	details=$4
	if [ $1 -eq 2 ];then
		job_state_log="job_${current_date} is running or done, ignore this execution!"
	elif [ $1 -eq 0 ];then
		job_state_log="job_${current_date} is running"
	elif [ $1 -eq 1 ];then
		job_state_log="job_${current_date} is done"
	elif [ $1 -eq -1 ];then
		job_state_log="job_${current_date} is failed"
	fi
	line=${current_time}"\t"${details}"\t"${job_state_log}
	echo -e ${line} > $logFile
	echo -e ${line} >> $detailFile
}
##############################
# @ check if job is running
if [ `cat ${job_log} | grep -E "job_${date} is running|job_${date} is done" | wc -l` -eq 1 ]
then
	update_detail 2 ${job_log} ${job_detail} "WAITING" ${date}
	exit 0
fi

update_detail 0 ${job_log} ${job_detail} "BEGIN" ${date}
rm ${out_dir} -rf
mkdir -p ${out_dir}

##############################
# @ parse data
cd ${parse_data_dir}
sh ./update_table.sh ${sql_date}
if [ $? -ne 0 ];then
	update_detail -1 ${job_log} ${job_detail} "fail parse data" ${date}
	exit 0
fi

##############################
# @ cac score
cd ${src_dir}
sh ./run.sh
if [ $? -ne 0 ];then
	update_detail -1 ${job_log} ${job_detail} "fail caculating score" ${date}
	exit 0
fi

##############################
# @ update DB
cd ${db_dir}
sh ./update.sh
if [ $? -ne 0 ];then
	update_detail -1 ${job_log} ${job_detail} "fail UPDATE TABLE" ${date}
	exit 0
fi
#############################
# @ job done flag
update_detail 1 ${job_log} ${job_detail} "END" ${date}
