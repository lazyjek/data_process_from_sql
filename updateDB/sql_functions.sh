#!/bin/bash
source ./writeSQL.conf
function init_table() {
	sub_sql=$1
	sub_schema=$2
	sub_table=$3
	sub_data=$4
	sub_key=$5
	desc_idx=$6
	key_idx=1
	num_end_idx=`expr ${desc_idx} - 1`
	echo ${num_end_idx}
	
	######################
	rm $sub_sql -rf
	######################
	# @delete data from tables, TEST ONLY
	echo "delete from ${WRITE_BD}.${sub_table};" > ${sub_sql}

	######################
	# @get each line.
	touch $sub_sql
	sql_script='s/^/insert into '${WRITE_BD}.${sub_table}'('${sub_schema}') values (/'
	sed -e 's/\t/:/g' ${sub_data} > data.tmp
	while read line
	do
		desc=`echo $line | cut -d ':' -f ${desc_idx}`
		key=`echo $line | cut -d ':' -f ${key_idx}`
		nums=`echo $line | cut -d ':' -f 1-${num_end_idx}`
		new_line=${nums}":\""${desc}"\""
		echo $new_line | sed -e 's/:/,/g'  -e "${sql_script}" -e 's/$/);/' >> ${sub_sql}
		echo "update ${WRITE_BD}.${sub_table} set add_time=now(), mod_time=now() where ${sub_key}=${key};" >> ${sub_sql}
	done < data.tmp 
	rm data.tmp -rf
	
	########################
	# @if sql ready, quit.
	if [[ $? -eq 0 ]]; then
		echo "get ${sub_sql} sql script success"
		echo "quit" >> ${sub_sql}
	else
		echo "fail get sql script"
		exit 1
	fi

	#######################
	# @write db.
	mysql --default-character-set=gbk -h${WRITE_HOST} -P${WRITE_PORT} -u${WRITE_USER} -p${WRITE_PASSWD} < ${sub_sql}
	if [[ $? -eq 0 ]]; then
		echo "write into ${sub_table} completed"
	else
		echo "fail write into table : ${sub_table}"
		exit
	fi
}

function get_params() {
	para_list=$1
	delma=$2
	end_idx=`echo $para_list | awk -v d=${delma} 'BEGIN{FS=d}{print NF}'`
	var_list=''
	for idx in `seq $end_idx`;do
		var=`echo ${para_list} | awk -v i=$idx -v d=${delma} 'BEGIN{FS=d}{print $i}'`
		var_list=$var_list' '$var;
	done; 
	echo $var_list
}

function update_table() {
	######################
	# @ data prepare
	sub_schema=$1
	sub_table=$2
	sub_data=$3
	
	key_idx=1
	paras=(`get_params $sub_schema ","`)
	desc_idx=`echo ${#paras[@]}`
	num_end_idx=`expr ${desc_idx} - 1`
	
	######################
	# @ update file to database
	sed -e 's/\t/:/g' ${sub_data} > batch_data.tmp
	while read line
	do
		new_line_insert=''
		new_line_update=''
		vals=(`get_params $line ":"`)
		for i in `seq $desc_idx`;do
			val=${vals[i-1]}
			para=${paras[i-1]}
			if [ $i -eq $desc_idx ];then
				val="\"${val}\""
			fi
			update_item="${para}=${val}"
			new_line_insert=${new_line_insert}':'${val}
			new_line_update=${new_line_update}','${update_item}
			if [ $i -eq 1 ];then
				new_line_insert=${val}
				new_line_update=${update_item}
			fi
			if [ $i -eq 2 ];then
				new_line_update=${update_item}
			fi
		done
		
		###########################
		# @ get script
		# @ add new lines.
		INSERT_LINE=`echo $new_line_insert | sed -e 's/:/,/g'  -e "s/^/INSERT IGNORE INTO ${WRITE_BD}.${sub_table}(${sub_schema},add_time,mod_time) VALUES (/" -e 's/$/,now(),now());/'`
		select_line=`echo $new_line_update | sed -e 's/=/!=/g' -e 's/,/ or /g'`
		new_line_update="${new_line_update} where ${paras[0]}=${vals[0]} and (${select_line})"
		# @ update exist lines.
		UPDATE_LINE="update ${WRITE_BD}.${sub_table} set mod_time=now(),${new_line_update}"
		##############################
		# @ write back to database
		mysql --default-character-set=gbk -h${WRITE_HOST} -P${WRITE_PORT} -u${WRITE_USER} -p${WRITE_PASSWD} << EOF
		use ${WRITE_BD};
		${INSERT_LINE}
		${UPDATE_LINE}
EOF
	done < batch_data.tmp
	rm batch_data.tmp -rf
}
