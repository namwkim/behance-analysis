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
ccount = 0
acount = 0
for i, user in enumerate(users):
    # print 'user',i
    # appreciation links
    acount += len(list(dbappreciations.find({'user_id': user['id']})))
    ccount += len(list(dbprojects.find({'owners.id': user['id']})))
print 'total users', len(users)
print 'total appreciations:',acount
print 'total creations:',ccount
