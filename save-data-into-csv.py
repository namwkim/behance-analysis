import os, pymongo, sys, csv, datetime, threading, json, random, time
import urllib2

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

dbusers     = db.users
dbprojects  = db.projects
dbappreciations = db.appreciations


print 'retrieving users...'
users = list(db.users.find({'gender':{'$ne':'unknown'}}))
# only 10% percent (comment this for full users)
percent = 100
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
        exists = False # if this project is in the project list?
        for owner in designs[0]['owners']:
            if userMap.has_key(owner['id']):
                exists = True
                break
        if exists==False:
            continue
        links.append((user['id'], designs[0]['id'], 'appreciate'))
        savedDesign[designs[0]['id']] = designs[0]

    # creation links
    created = list(dbprojects.find({'owners.id': user['id']}))
    project_comments = 0
    for c in created:
        links.append((user['id'], c['id'], 'create'))
        savedDesign[c['id']] = c
        project_comments += c["stats"]["comments"]

    user['project_counts'] = len(created)
    user['project_comments'] = project_comments
    savedUsers[user['id']] = user


users = savedUsers.values()
designs = savedDesign.values()

print '#of users:',len(users)
print '#of designs:',len(designs)
print '#of links:',len(links)
print '#of appreciate-links:', len(filter(lambda x: x[2]=='appreciate', links))
print '#of create-links:', len(filter(lambda x: x[2]=='create', links))

# print 'save into csv files'
userwriter = csv.writer(open("./data/sampled-graph/users-"+str(percent)+".csv", 'wb'));
userwriter.writerow(['user_id', 'fields', 'followers', 'following', 'username',\
    'gender', 'country', 'comments', 'project_counts', 'project_views', \
    'project_appreciations', 'project_comments', 'created_on'])
for user in users:
    record = [user['id'], '|'.join(user['fields']), \
        user['stats']['followers'], user['stats']['following'], user['username'],\
        user["gender"], user["country"], user["stats"]["comments"], \
        user['project_counts'], user["stats"]["views"], user["stats"]["appreciations"],\
        user['project_comments'], user["created_on"]]
    record 	=[ s.encode('utf-8') if isinstance(s, unicode) else s for s in record]
    userwriter.writerow(record)

desigwriter = csv.writer(open("./data/sampled-graph/designs-"+str(percent)+".csv", 'wb'));
desigwriter.writerow(['design_id', 'fields', 'appreciations', 'url'])
for design in designs:
    desigwriter.writerow([design['id'], "|".join(design['fields']), \
        design['stats']['appreciations'],\
        design['url']])

linkwriter = csv.writer(open("./data/sampled-graph/links-"+str(percent)+".csv", 'wb'));
linkwriter.writerow(['user_id', 'design_id', 'type'])
for link in links:
    linkwriter.writerow([link[0], link[1], link[2]])
