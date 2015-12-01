import os, pymongo, sys, csv, datetime, json

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance
dbcol       = db.recent_projects
dbseed      = db.seed_users
dbseed.remove({})
projects = dbcol.find().sort("project.published_on", pymongo.ASCENDING)

seedUsers = {}
for p in projects:
    p =  p["project"]
    print datetime.datetime.fromtimestamp(p["published_on"]).strftime('%Y-%m-%d %H:%M:%S')
    owners = p["owners"]
    for user in owners:
        if seedUsers.has_key(user["id"]): #save unique users
            continue
        print "Saving...", user["username"]
        dbseed.insert({ "user": json.loads(json.dumps(user.copy()))})
        seedUsers[user["id"]] = user

print "# of users saved: ", len(seedUsers)
