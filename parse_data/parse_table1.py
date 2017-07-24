#!/usr/bin/env python
#-*- coding:gbk -*-
import sys
import gc
import os
import json
import codecs
import time
import datetime
gc.disable()

from data_parser import table1_parser_t
from parse_html_line import html_image, html_content

table1_dict = {}
image_list_names = ['List1','List2','List3']
_key_dict = {
        1:'image_count1',
        2:'content_count',
        3:'score',
        4:'image_count2'
        }

def update_dict(dicts, key1, key2, value):
    if isinstance(value, int):
        init_value = 0
    elif isinstance(value, list):
        init_value = []
    elif isinstance(value, float):
        init_value = 0.0

    if key1 not in dicts:
        dicts[key1] = {}
    if key2 not in dicts[key1]:
        dicts[key1][key2] = init_value
    dicts[key1][key2] += value
    
    # dedup list.
    if isinstance(value, list):
        dicts[key1][key2] = list(set(dicts[key1][key2]))

def check_time_stamp(update_time):
    log_time = datetime.datetime.today()-datetime.timedelta(2)
    log_time = log_time.strftime('%Y-%m-%d %H:%M:%S')
    log_stamp = time.mktime(time.strptime(log_time, '%Y-%m-%d %H:%M:%S'))
    update_stamp = time.mktime(time.strptime(update_time, '%Y-%m-%d %H:%M:%S'))
    if update_stamp < log_stamp:
        return False
    else:
        return True

def load_table1_data(filename):
    p = table1_parser_t()
    for line in open(filename):
        if not p.refresh(line.strip()):
            # check update time.
            if check_time_stamp(p.update_time) == False:
                continue
            # get key.
            key = p.key
            
            # image num and content num from html.
            html_list = [p.value1, p.value2]
            image_count1 = html_image(html_list)
            content_count,content_detail = html_content(html_list)
            
            # image num from json.
            image_list = []
            try:
                json_str = p.value5.replace("\\\\\"", "");
                json_str = json_str.replace("\\\\","");
                json_dict = json.loads(json_str)
                for j_key in json_dict:
                    if j_key in image_list_names:
                        image_list += json_dict[j_key]
            except:
                pass
 
            # comment
            try:
                score = float(p.value3)
            except:
                score = 0.1
            
            update_dict(table1_dict, key, _key_dict[1], image_count)
            update_dict(table1_dict, key, _key_dict[2], content_count)
            update_dict(table1_dict, key, _key_dict[3], score)
            update_dict(table1_dict, key, _key_dict[4], image_list)

def update():
    file_dir = os.path.split(os.path.realpath(__file__))[0]
    load_data(file_dir + '/file1.dat')

update()
