import sys, os, urllib, csv, urlparse, time, pymongo, random
import numpy as np
# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance
dbprojects  = db.projects
# projects = list(dbprojects.find())
users = list(db.users.find({'gender':{'$ne':'unknown'}}))
print 'Total users with gender:', len(users)
projects = []
i = 0
for user in users:
    i+=1
    print i
    projects.extend(list(db.projects.find({'owners.id':user['id']})))

for idx, project in enumerate(projects):
    projID          = project['id']
    if isinstance(project["covers"], list) or project["covers"]["202"]==None:
        print 'url is not found:', project["covers"]
        continue
    projImageURL    = project["covers"]["202"]
    ext = os.path.splitext(urlparse.urlparse(projImageURL).path)[1]
    print idx, "retrieving",str(projID)+ext
    if os.path.exists('./images/'+str(projID)+".jpg")\
        or os.path.exists('./images/'+str(projID)+".png")\
        or os.path.exists('./images/'+str(projID)+".gif"):
        print '- file exists.'
        continue
    if projImageURL != None:
        try:
            urllib.urlretrieve(projImageURL, './images/'+str(projID)+ext)
            time.sleep(0.01)
        except Exception as e:
            print e
            continue
