#!/bin/bash
#########################
# @ data prepare
source ../env.conf
source ./mysql.conf
sdate=`date -d "-2 days" +%s`
if [ $1 ];then
	sdate=`date -d "$1" +%s`
fi
work_dir=$(cd `dirname $0`; pwd)
root_dir=$(dirname ${work_dir})
log_file=${root_dir}/log/log_file
rm ${log_file} -rf
echo `date +%Y-%m-%d:%H:%M:%S` > ${log_file}

table1=${work_dir}/file1.dat
table2=${work_dir}/file2.dat
table3=${work_dir}/file3.dat
########################
# @ get sql
# @ source : table3
mysql --default-character-set=gbk -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWD} ${MYSQL_DATABASE} -e \
	"select * from ${TABLE_NAME3}" > ${table3}.temp

# @ source : table2
mysql --default-character-set=gbk -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWD} ${MYSQL_DATABASE} -e \
	"select ${PARAM_SCHEMA2} from ${TABLE_NAME2} " > ${table2}

# @ source : table1
mysql --default-character-set=gbk -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWD} ${MYSQL_DATABASE} -e \
	"select ${PARAM_SCHEMA1} from ${TABLE_NAME1} where value5=0 and (value4 = 1 or value4 = 0)" | awk -F '\t' '{print $1"\t"$3}' > ${table1}.temp

mysql --default-character-set=gbk -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWD} ${MYSQL_DATABASE} -e \
	"select ${PARAM_SCHEMA1} from ${TABLE_NAME1} \
    Where unix_timestamp(update_time) > $sdate and value5=0 and (value4 = 1 or value4 = 0)" > ${table1}

# @ 
awk -F '\t' 'NR==FNR{o[$1]=1}NR>FNR{if(o[$3]==1)print $2"\t"$3"\t"$5 fi}' ${table1}.temp ${table3}.temp > ${table3}
rm ${table1}.temp ${table3}.temp -rf
########################
# @ post proc
sed '1d' ${table1} -i
sed '1d' ${table2} -i
sed '1d' ${table3} -i

#######################
# @check data
date=`date +%Y%m%d`
dat_num=`ls -l | grep "\.dat" | wc -l`
if [ $dat_num -lt 2 ];then
	echo "sql data ${date} lost file !" >> ${log_file}
	return 1
fi

storage_list=`ls -l | grep "\.dat" | awk '{print $5}'`
for sub_space in $storage_list
do
	if [ $sub_space -eq 0 ]
	then
		echo "parse data ${date} is empty !" >> ${log_file}
		return 1
	fi
done
