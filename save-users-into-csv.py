import os, pymongo, sys, csv, datetime, threading, json, random, time
import urllib2

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

dbusers         = db.users
dbprojects      = db.projects
dbcollections   = db.collections

print 'collecting users'
users       = []
for user in dbusers.find():
    users.append(user)

print 'collecting projects'
user_projs = {}
for project in dbprojects.find():
    for user in project["owners"]:
        if user_projs.has_key(user['id'])==False:
            user_projs[user['id']] = []
        user_projs[user['id']].append(project)

print 'collecting collections'
user_cols = {}
for coll in dbcollections.find():
    for user in coll["owners"]:
        if user_cols.has_key(user['id'])==False:
            user_cols[user['id']] = []
        user_cols[user['id']].append(coll)



# print filename
with open("./sampled-graph/behance-users.csv", 'wb') as csvfile:
    userwriter = csv.writer(csvfile);

    header = [
        "user_id",
        "username"
        "first_name",
        "last_name",
        "created_on",
        # "gender",
        "city",
        "state",
        "country",
        "occupation",
        "fields",
        "followers",
        "following",
        "project_counts",
        "project_views",
        "project_appreciations",
        "project_comments",
        "collection_counts",
        "collection_item_counts",
        "collection_followers"
    ]
    userwriter.writerow(header)
    for user in users:
        print "processing", user["username"], "..."
        # project relevant derived measures
        prject_comments = 0
        if user_projs.has_key(user["id"]):
            projects = user_projs[user["id"]]
            for project in projects:
                prject_comments = prject_comments + project["stats"]["comments"]
        else:
            projects = []
        # collection relevant derived measures

        coll_items = 0
        coll_followers = 0
        if user_cols.has_key(user['id']):
            colls = user_cols[user["id"]]
            for coll in colls:
                coll_items      = coll_items + coll["stats"]["items"]
                coll_followers  = coll_items + coll["stats"]["followers"]
        else:
            colls = []
        record = [
            user["user_id"],
            user["username"],
            user["first_name"],
            user["last_name"],
            user["created_on"],
            # user["gender"], # estimated
            user["city"],
            user["state"],
            user["country"],
            user["occupation"],
            "|".join(user["fields"]),
            user["stats"]["followers"],
            user["stats"]["following"],
            len(projects),
            user["stats"]["views"],         # project views
            user["stats"]["appreciations"], # project appreciates
            prject_comments,                # project comments
            len(colls),
            coll_items,
            coll_followers
        ]
        record 	=[ s.encode('utf-8') if isinstance(s, unicode) else s for s in record]
        userwriter.writerow(record)
