import os, pymongo, sys, csv, datetime, threading, json, random, time

import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import numpy as np


# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

dbusers     = db.users
dbprojects  = db.projects
dbappreciations = db.appreciations

userMap = {}
appreciate_design_map = {}
create_design_map = {}
designMap = {}
links = []
users = []
print 'construct design map...'
for design in dbprojects.find():
    designMap[design['id']] = design
# appreciated projects
print 'construct appreciated designs'
progress = 0
for user in dbusers.find():
    progress+=1
    print '----------1.',progress, '----------'
    # if len(user['fields'])==0:
    #     continue
    users.append(user)
    appreciated = dbappreciations.find({'user_id': user['id']})
    appreciated_count = 0
    for a in appreciated:
        did = a['project_id']
        if designMap.has_key(did)==False:
            continue
        design = designMap[did]
        # if len(design['fields'])==0:
        #     continue
        appreciate_design_map[design['id']] = design
        # add an appreciate-link
        # print ','.join((str(user['id']), str(design['id']), 'appreciate'))
        links.append((user['id'], design['id'], 'appreciate'))
        appreciated_count += 1
    if appreciated_count>0:
        userMap[user['id']] = user


# created projects (at least appreciated once)
print 'construct created projects'

progress = 0
for user in users:
    progress+=1
    print '----------2.',progress, '----------'
    created = dbprojects.find({'owners.id': user['id']})
    created_count = 0
    for design in created:
        if appreciate_design_map.has_key(design['id']):#appreciated once at least
            create_design_map[design['id']] = design
            # add an appreciate-link
            # print ','.join((str(user['id']), str(design['id']), 'create'))
            links.append((user['id'], design['id'], 'create'))
            created_count+=1
    if created_count>0:
        userMap[user['id']] = user

designs = []
progress = 0
for design in designMap.values():
    progress+=1
    print '----------3.',progress, '----------'
    if appreciate_design_map.has_key(design['id']) or \
        create_design_map.has_key(design['id']):
        designs.append(design)
users = userMap.values()

print '#of users:',len(users)
print '#of designs:',len(designs)
print '#of links:',len(links)
print '#of appreciate-links:', len(filter(lambda x: x[2]=='appreciate', links))
print '#of create-links:', len(filter(lambda x: x[2]=='create', links))

print 'save into csv files'
userwriter = csv.writer(open("./induced-graph/users.csv", 'wb'));
userwriter.writerow(['user_id', 'fields', 'followers', 'followees', 'username'])
for user in users:
    userwriter.writerow([user['id'], '|'.join(user['fields']), \
        user['stats']['followers'], user['stats']['following'], user['username']])

desigwriter = csv.writer(open("./induced-graph/designs.csv", 'wb'));
desigwriter.writerow(['design_id', 'fields', 'appreciations', 'url'])
for design in designs:
    desigwriter.writerow([design['id'], "|".join(design['fields']), \
        design['stats']['appreciations'],\
        design['url']])

linkwriter = csv.writer(open("./induced-graph/links.csv", 'wb'));
linkwriter.writerow(['user_id', 'design_id', 'type'])
for link in links:
    linkwriter.writerow([link[0], link[1], link[2]])
