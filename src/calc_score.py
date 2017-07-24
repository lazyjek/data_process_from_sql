#!/user/bin/env python
#-*- coding:gbk -*-
import sys
import os
import copy
import logging
import ConfigParser

from parse_data.parse_table1 import table1_dict,_key_dict
from parse_data.parse_table23 import table2_dict,table3_dict

file_dir = os.path.split(os.path.realpath(__file__))[0]
root_dir = os.path.dirname(file_dir)

table1_schema = [
        'key', #1
        'value1', #2
        'value2', #3
        'value3',# 4,
        'value4',# 5,
        ]

# 全部左闭右开
criteria = {
    'score1' : {
        'weight' : 0.3,
        'seg' : [(-10000,1), (1,10), (10,100), (100,1000), (1000,sys.maxint)]
        },
    'score2' : {
        'weight' : 0.3,
        'seg' : [(-10000,1), (1,10), (10,100), (100,1000), (1000,sys.maxint)]
        },
    'score3' : {
        'weight' : 0.2,
        'seg' : [(-0.1,0.2), (0.2,0.5), (0.5,0.7), (0.7,0.9), (0.9,1.0)]
        },
    'score4' : {
        'weight' : 0.2,
        'seg' : [(-0.1,0.2), (0.2,0.5), (0.5,0.7), (0.7,0.9), (0.9,1.0)]
        },
}

index_dict = {
    'score1' : ('int', 1),
    'score2' : ('float', 3),
    'score3' : ('float', 4),
    'score4' : ('int', 2),
}

def parse_data(items):
    data = {}
    for key in index_dict:
        (type, idx) = index_dict[key]
        idx = idx - 1
        value = 0
        try:
            if type == 'int':
                value = int(items[idx])
            elif type == 'float':
                value = float(items[idx])
            data[key] = value
        except:
            logging.warning("cannot convert:%s,%s(%s)" % (key, type, items[idx]))
            return None
    return data

def calc_score(data):
    total_score = 0.0
    score_dict = {}
    for key in criteria:
        weight = criteria[key]['weight']
        value = data[key]
        seg_ary = criteria[key]['seg']
        sub_score = 0.0
        for i in range(0, len(seg_ary)):
            (minv, maxv) = seg_ary[i]
            if minv <= value < maxv:
                sub_score = (i + 1) * 100
        score_dict[key] = sub_score
        total_score += sub_score * weight
    score_dict['total_score'] = total_score
    return score_dict


def parse_line(line):
    items = line
    if len(items) != len(table1_schema):
        logging.warning("format error:%s", line)
        return
    data = parse_data(items)
    if data == None:
        return
    score_dict = calc_score(data)
    return score_dict


if __name__ == '__main__':
    reload(sys)
    sys.setdefaultencoding('gbk')
    split_delma = "%s\t%s\t" + "\t".join(["%d"]*4) + "\t%s"
    score_dict = {}
    for key in table1_dict:
        line = [str(table1_dict[key][_key_dict[i+1]]) for i in range(len(_key_dict))]
        score_dict[key] = parse_line(line)
    for key in score_dict:
        u_string = split_delma%tuple(score_dict[key][table1_schema[i]] for i in range(len(table1_schema)))
        print unicode.encode(u_string, 'gbk', 'ignore')
