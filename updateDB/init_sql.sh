#!/bin/bash
source writeSQL.conf
source ./sql_functions.sh
data1="../../output/score"
sql1="./data1.sql"

tmp=(`echo ${SCHEMA1} | sed -e 's/,/ /g'`)
count=${#tmp[@]}
init_table ${sql1} ${SCHEMA1} ${TABLE1} ${data1} key $count
rm *.sql -rf
