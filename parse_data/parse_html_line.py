#!/usr/bin/env python
#-*- coding:gbk -*-
import sys,os
from BeautifulSoup import BeautifulSoup, NavigableString
import re


def strip_tags(html, invalid_tags):
    soup = BeautifulSoup(html, fromEncoding="gbk")
    for tag in soup.findAll(True):
        if tag.name in invalid_tags:
            s = ""

            for c in tag.contents:
                if not isinstance(c, NavigableString):
                    c = strip_tags(unicode(c), invalid_tags)
                s += unicode(c)
            tag.replaceWith(s)
            
    return soup

def remove_tags(html):
    soup = BeautifulSoup(html, fromEncoding="gbk")
    for tag in soup.findAll(True):
        s = ""

        for c in tag.contents:
            if not isinstance(c, NavigableString):
                c = remove_tags(unicode(c))
            s += unicode(c)
        tag.replaceWith(s)
            
    return soup


def catch_tags(html, tag_attr_dict, attr_val_set):
    soup = BeautifulSoup(html, fromEncoding="gbk")
    for m_tag in tag_attr_dict:
        m_attr = tag_attr_dict[m_tag]
        tagList = soup.findAll(m_tag, attrs={m_attr:True})
        for tagVal in tagList:
            attrVal = tagVal[m_attr]
            attr_val_set.add(attrVal)
    
def html_image(line_list):
    tag_attr_dict = {'img':'src'}
    image_set = set()
    
    for line in line_list:
        catch_tags(line, tag_attr_dict, image_set)
    
    return len(image_set)

def html_content(line_list):
    content_len = 0
    content_details = ''
    for line in line_list:
        soup_content = remove_tags(line)
        try :
            content = soup_content.__str__('GBK').replace('&nbsp;', ' ')
            content = content.replace("\\n", "")
            content = content.replace("\\t", "")
            content = content.replace("\r", "")
            content = content.replace("\r\n", "")
            content_details += content
            content_len += len(content.decode('gbk','ignore'))
        except:
            continue
    
    #return content_details
    return content_len,content_details
