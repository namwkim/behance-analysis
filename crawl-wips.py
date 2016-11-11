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
dbwips  = db.wips
dbwips.remove({}) # clear existing db collection

visitedWips = {}

users = []
for user in dbusers.find():
    users.append(user)

numUser = 0
numWips = 0
for user in users:
    numUser = numUser + 1
    print "Retrieving wips from user id: ", user["user_id"], " (", numUser, ")"
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
            wips = u.get_wips(page=pageNum)
            if len(wips)==0:
                break;

            for wip in wips:
                # avoid duplicate
                if visitedWips.has_key(wip["id"]):
                    continue
                visitedWips[wip["id"]] = wip
                dbwips.insert(json.loads(json.dumps(wip), object_hook=remove_dot_key))
                numWips +=1
            print "PageNum (Total wips) = ", pageNum, ", ", numWips
            pageNum +=1
            if pageNum>=400:
                break
        except TooManyRequests as e:
            print "Maximum Request Reached! Wating for Next Hour..."
            time.sleep(60) # retry after 1 min
            continue
        except BehanceException as e:
            print "BehanceException: ", str(e)
            break

print "Total wips, Users =  ", numWips, ", ", numUser
