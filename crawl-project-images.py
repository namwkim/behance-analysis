import sys, os, urllib, csv, urlparse, time, pymongo

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance
dbprojects  = db.projects
projects = list(dbprojects.find())

for idx, project in enumerate(projects):
    projID          = project['id']
    if isinstance(project["covers"], list) or project["covers"]["original"]==None:
        print 'url is not found:', project["covers"]
        continue
    projImageURL    = project["covers"]["original"]
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
