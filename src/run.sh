#!/bin/bash
source ../env.conf
src_dir=$(cd `dirname $0`; pwd)
root_dir=$(dirname ${src_dir})
out_dir=${root_dir}/output
rm ${out_dir}/*.${date} -rf
date=`date +%Y%m%d`

###########################
# @ src dir
cd ${src_dir}

rm parse_data -rf
ln -sf ../parse_data parse_data
echo "after parse data"`pwd`

#########################
# @ calc score
cd ${src_dir} && ${_PYTHON_} calc_score.py > ${out_dir}/score.${date}
if [ $? -ne 0 ];then
	echo "${date} calc score fail !"
fi
cd ${out_dir} && ln -sf score.${date} score

##########################
# @ out dir
cd ${out_dir}
dat_num=`ls -l | grep "score\.${date}" | wc -l`
if [ $dat_num -lt 1 ];then
	echo "score data ${date} lost file !"
	exit 1
fi

storage_list=`ls -l | grep "score\.{date}" | awk '{print $5}'`
for sub_space in $storage_list
do
	if [ $sub_space -eq 0 ]
	then
		echo "score ${date} is empty !"
		exit 1
	fi
done
