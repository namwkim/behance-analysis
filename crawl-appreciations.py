import os, pymongo, sys, csv, datetime, threading, json, random, time
from behance_python.api import API
from behance_python.exceptions \
    import TooManyRequests, InternalServerError, BehanceException
from behance_python.behance import Behance
from behance_python.user import User

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

dbusers     = db.users
dbappreciations  = db.appreciations
dbappreciations.remove({}) # clear existing db collection

visitedProjects = {}

users = []
for user in dbusers.find():
    users.append(user)

numUser = 0
numAppreciations = 0
for user in users:
    numUser = numUser + 1
    print "Retrieving appreciations from user id: ", user["user_id"], " (", numUser, ")"
    while True:
        try:
            u = User(user["user_id"], user["auth_key"])
            break
        except TooManyRequests as e:
            print "Maximum Request Reached! Wating for Next Hour..."
            time.sleep(60) # retry after 1 min
            continue
        except BehanceException as e:
            print "BehanceException: ", str(e)
            break

    pageNum = 1
    while True:
        try:
            appreciations = u.get_appreciations(page=pageNum)

            if len(appreciations)==0:
                break
            for appreciation in appreciations:
                dbappreciations.insert({'user_id':user["user_id"], 'project_id':appreciation['project']['id']})
            numAppreciations+=len(appreciations)

            print "PageNum (Total Projects) = ", pageNum, ", ", numAppreciations
            pageNum +=1
            if pageNum>5:
                break
        except TooManyRequests as e:
            print "Maximum Request Reached! Wating for Next Hour..."
            time.sleep(60) # retry after 1 min
            continue
        except BehanceException as e:
            print "BehanceException: ", str(e)
            break

print "Total Projects, Users =  ", numAppreciations, ", ", numUser
