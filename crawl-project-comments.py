import os, pymongo, sys, csv, datetime, threading, json, random, time
from behance_python.api import API
from behance_python.exceptions \
    import TooManyRequests, InternalServerError, BehanceException
from behance_python.behance import Behance
from behance_python.user import User
from behance_python.project import Project

def remove_dot_key(obj):
    for key in obj.keys():
        new_key = key.replace(".","")
        if new_key != key:
            obj[new_key] = obj[key]
            del obj[key]
    return obj

# set API key
key = raw_input('Input your Behance API key: ');
behance = API(key)

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

dbcomments  = db.project_comments
dbcomments.remove({}) # clear existing db collection
# visitedComments = dict(map(lambda x: (x['comment']['id'], x), list(dbcomments.find())))

users = list(db.users.find({'gender':{'$ne':'unknown'}}))
print 'Total users with gender:', len(users)
projects = []
i = 0
for user in users:
    i+=1
    print i
    projects.extend(list(db.projects.find({'owners.id':user['id']})))

print 'sort projects by id...'
projects.sort(key=lambda x:x['id'])

numComments = 0
numProj = 0
exceptions = 0
for project in projects:
    numProj = numProj + 1
    print "Retrieving project comments from project id: ", project["id"], " (", numProj, ")"
    while True:
        try:
            p = Project(project["id"], key)
            break
        except TooManyRequests as e:
            print "Maximum Request Reached! Wating for Next Hour..."
            time.sleep(60) # retry after 1 min
            continue
        except BehanceException as e:
            print "BehanceException: ", str(e)
            exceptions = exceptions+1
            break

    while True:
        try:
            comments = p.get_comments()
            for comment in comments:
                data = json.loads(json.dumps(comment), object_hook=remove_dot_key)
                data['user'].pop('images', None)
                data['project_id'] = project['id']
                dbcomments.insert(data)
                numComments +=1
            print "Project ID, Total Comments = ", project["id"], ", ", numComments
            break
        except TooManyRequests as e:
            print "Maximum Request Reached! Wating for Next Hour..."
            time.sleep(60) # retry after 1 min
            continue
        except BehanceException as e:
            print "BehanceException: ", str(e)
            exceptions = exceptions+1
            break

print "Total Comments, Projects =  ", numComments, ", ", numProj
