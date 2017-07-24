#!/usr/bin/env python
#-*- coding:gbk -*-
import sys
import gc
import os
import codecs
import time
gc.disable()

from data_parser import table2_parser_t, table3_parser_t
table2_dict = {}
table3_dict = {}

def load_data(filename,p):
    table_dict = {}
    for line in open(filename, 'r'):
        if not p.refresh(line.strip()):
            # define how to load data from data base.
            if p.key not in table_dict:
                table_dict[p.key] = set()
            table_dict[p.key].add(p.value1)
    return table_dict

def update():
    file_dir = os.path.split(os.path.realpath(__file__))[0] 
    p = table2_parser_t()
    table2_dict = load_data(file_dir + '/file2.dat', p)
    p = table3_parser_t()
    table3_dict = load_data(file_dir + '/file3.dat', p)

update()
