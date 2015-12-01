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

dbusers     = db.sample_users
dbcollection  = db.sample_collections
dbcollection.remove({}) # clear existing db collection

visitedCols = {}

users = []
for user in dbusers.find():
    users.append(user)

numUser = 0
numCols = 0
for user in users:
    numUser = numUser + 1
    print "Retrieving cols from user id: ", user["user_id"], " (", numUser, ")"
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
            cols = u.get_collections(page=pageNum)
            if len(cols)==0:
                break;

            for col in cols:
                # avoid duplicate
                if visitedCols.has_key(col["id"]):
                    continue
                visitedCols[col["id"]] = col
                dbcollection.insert(json.loads(json.dumps(col), object_hook=remove_dot_key))
                numCols +=1
            print "PageNum (Total cols) = ", pageNum, ", ", numCols
            pageNum +=1
        except TooManyRequests as e:
            print "Maximum Request Reached! Wating for Next Hour..."
            time.sleep(60) # retry after 1 min
            continue
        except BehanceException as e:
            print "BehanceException: ", str(e)
            break

print "Total cols, Users =  ", numCols, ", ", numUser
