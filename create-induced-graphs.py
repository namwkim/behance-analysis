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



print 'retrieving users...'
users = list(db.users.find({'gender':{'$ne':'unknown'}}))
# only 10% percent (comment this for full users)
percent = 50
users = random.sample(users, int(len(users)*percent/100.0))
print 'number of users:', len(users)
userMap  = {user['id']:user for user in users}
links = []
savedDesign = {}
savedUsers = {}
for i, user in enumerate(users):
    print 'user',i
    # appreciation links
    appreciated = dbappreciations.find({'user_id': user['id']})
    for a in appreciated:
        designs = list(dbprojects.find({'id':a['project_id']}))#.size()
        if len(designs)==0:
            continue
        if len(designs[0]['fields'])==0:
            continue
        exists = False
        for owner in designs[0]['owners']:
            if userMap.has_key(owner['id']):
                exists = True
                break
        if exists==False:
            continue
        links.append((user['id'], designs[0]['id'], 'appreciate'))
        savedDesign[designs[0]['id']] = designs[0]
        savedUsers[user['id']] = user

    # creation links
    created = dbprojects.find({'owners.id': user['id']})
    for c in created:
        if len(c['fields'])==0:
            continue
        designs= list(dbappreciations.find({'project_id':c['id']}))
        if len(designs)==0:
            continue
        exists = False
        for ids in designs:
            if userMap.has_key(ids['user_id']):
                exists = True
                break
        if exists==False:
            continue
        links.append((user['id'], c['id'], 'create'))
        savedDesign[c['id']] = c
        savedUsers[user['id']] = user
        # add an appreciate-link
        # print ','.join((str(user['id']), str(design['id']), 'appreciate'))

        # appreciated_count += 1
    # if appreciated_count>0:
    #     userMap[user['id']] = user


users = savedUsers.values()
designs = savedDesign.values()
# for link in links:
#     if link[2]=='create':
#         size = len(filter(lambda l: l[2]=='appreciate' and l[1]==link[1], links))
#         if size==0:
#             raise Exception('no appreciation link found');
#     else:
#         size = len(filter(lambda l: l[2]=='create' and l[1]==link[1], links))
#         if size==0:
#             raise Exception('no create link found');


#
# # created projects (at least appreciated once)
# print 'constructing creation-links and users...'
#
# progress = 0
# linkMap = {}
# for user in users:
#     progress+=1
#     print '----------2.',progress, '----------'
#     created = dbprojects.find({'owners.id': user['id']})
#     created_count = 0
#     for design in created:
#         # appreciated once at least
#         if appreciate_design_map.has_key(design['id']):
#             create_design_map[design['id']] = design
#             # create creation links
#             links.append((user['id'], design['id'], 'create'))
#             created_count+=1
#     # save users if created at least one design that is appreciated at least once
#     if created_count>0: #
#         userMap[user['id']] = user
#
# print 'constructing appreciation-links...'
# for design_id, design in appreciate_design_map.iteritems():
#     if create_design_map.has_key(design_id):
#         links.append((user_id, design_id, 'appreciate'))
#
#
# print 'constructing designs...'
# designs = []
# progress = 0
# for design in create_design_map.values():
#     progress+=1
#     print '----------3.',progress, '----------'
#     if appreciate_design_map.has_key(design['id']):
#         designs.append(design)
# print 'constructing users...'
# users = userMap.values()
#
print '#of users:',len(users)
print '#of designs:',len(designs)
print '#of links:',len(links)
print '#of appreciate-links:', len(filter(lambda x: x[2]=='appreciate', links))
print '#of create-links:', len(filter(lambda x: x[2]=='create', links))

print 'save into csv files'
userwriter = csv.writer(open("./data/induced-graph/users-"+str(percent)+".csv", 'wb'));
userwriter.writerow(['user_id', 'fields', 'followers', 'followees', 'username'])
for user in users:
    userwriter.writerow([user['id'], '|'.join(user['fields']), \
        user['stats']['followers'], user['stats']['following'], user['username']])

desigwriter = csv.writer(open("./data/induced-graph/designs-"+str(percent)+".csv", 'wb'));
desigwriter.writerow(['design_id', 'fields', 'appreciations', 'url'])
for design in designs:
    desigwriter.writerow([design['id'], "|".join(design['fields']), \
        design['stats']['appreciations'],\
        design['url']])

linkwriter = csv.writer(open("./data/induced-graph/links-"+str(percent)+".csv", 'wb'));
linkwriter.writerow(['user_id', 'design_id', 'type'])
for link in links:
    linkwriter.writerow([link[0], link[1], link[2]])
