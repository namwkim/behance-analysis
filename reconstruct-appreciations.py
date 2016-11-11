import os, pymongo, sys, csv, datetime, threading, json, random, time


# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance
appreciations  = db.appreciations
cols = db.aprc

for col in cols.find():
    appreciations.insert({'user_id':col['user_id'], \
        'project_id':col['appreciated']['project']['id']})
