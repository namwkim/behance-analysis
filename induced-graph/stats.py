import os, pymongo, sys, csv, datetime, threading, json, random, time

import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import numpy as np


print 'reading and hashing links'
# header = ['user_id', 'design_id', 'type']
linkreader = csv.reader(open("links.csv", 'r'));
links = []
linkreader.next()
create_links_by_user = {}
appreciate_links_by_design = {}
for link in linkreader:
    links.append(link)
    if link[2]=='create':
        if create_links_by_user.has_key(link[0])==False:
            create_links_by_user[link[0]] = []
        create_links_by_user[link[0]].append(link)
    if link[2]=='appreciate':
        if appreciate_links_by_design.has_key(link[1])==False:
            appreciate_links_by_design[link[1]] = []
        appreciate_links_by_design[link[1]].append(link)

print 'reading users'
# header = ['user_id', 'fields', 'followers', 'followees', 'username']
userreader = csv.reader(open("users.csv", 'r'));
users = []
userreader.next()
# create_lnks = []
for user in userreader:
    users.append(user)
    # creation links
    # create_lnks.append(len(filter(lambda x: x[0]==user[0],links)))

print 'reading designs'
# header = ['design_id', 'fields', 'appreciations', 'url']
designreader = csv.reader(open("designs.csv", 'r'));
designs = []
designreader.next()
# appreciate_lnks = []
for design in designreader:
    designs.append(design)
    # appreciation links
    # appreciate_lnks.append(len(filter(lambda x: x[1]==design[0],links)))

create_links = map(lambda x:len(x), create_links_by_user.values())
appreciate_lnks = map(lambda x:len(x), appreciate_links_by_design.values())
print '#of users:',len(users), '(M=',np.mean(create_links),\
    ',SD=', np.std(create_links), \
    ',min=', min(create_links), \
    ',max=', max(create_links),')'
print '#of designs:',len(designs), '(M=',np.mean(appreciate_lnks), \
    ',SD=', np.std(appreciate_lnks), \
    ',min=', min(appreciate_lnks), \
    ',max=', max(appreciate_lnks),')'
print '#of links:',len(links)
print '#of appreciate-links:', len(filter(lambda x: x[2]=='appreciate', links))
print '#of create-links:', len(filter(lambda x: x[2]=='create', links))
