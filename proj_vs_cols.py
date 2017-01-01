import os
import pymongo
import sys
import numpy as np

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db = localClient.behance

dbusers = db.users
dbprojects = db.projects
dbcollections = db.collections


print 'retrieving users...'
users = list(db.users.find({'gender': {'$ne': 'unknown'}}))

coll_counts = []
proj_counts = []
coll_item_counts = []
for i, user in enumerate(users):
    print 'user', i

    # creation links
    proj_cnt = len(list(dbprojects.find({'owners.id': user['id']})))
    collections = list(dbcollections.find({'owners.id': user['id']}))
    for col in collections:
        coll_item_counts.append(col['stats']['items'])
    coll_cnt = len(collections)


    proj_counts.append(proj_cnt)
    coll_counts.append(coll_cnt)



print 'AVG.PROJECT-% (MEAN, STD):', "M={0:.2f}".format(np.mean(proj_counts))+', '+\
        "SD={0:.2f}".format(np.std(proj_counts))

print 'AVG.COLLECTION-% (MEAN, STD):', "M={0:.2f}".format(np.mean(coll_counts))+', '+\
        "SD={0:.2f}".format(np.std(coll_counts))+\
        ", MEDIAN={0:.2f}".format(np.median(coll_counts))

print 'AVG.COLLECTION ITEM-% (MEAN, STD):', "M={0:.2f}".format(np.mean(coll_item_counts))+', '+\
        "SD={0:.2f}".format(np.std(coll_item_counts))+\
        ", MEDIAN={0:.2f}".format(np.median(coll_item_counts))
