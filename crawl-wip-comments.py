import os, pymongo, sys, csv, datetime, threading, json, random, time
from behance_python.api import API
from behance_python.exceptions \
    import TooManyRequests, InternalServerError, BehanceException
from behance_python.behance import Behance
from behance_python.wip import WIP

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

dbwips     = db.sample_wips
dbcomments = db.sample_wip_comments
dbcomments.remove({}) # clear existing db collection

visitedComments = {}

wips = []
for wip in dbwips.find():
    wips.append(wip)

numWips = 0
numComments = 0
numExceptions = 0
for wip in wips:
    numWips = numWips + 1
    print "Retrieving comments from wip id: ", wip["id"], " (", numWips, ")"
    while True:
        try:
            w = WIP(wip["id"], key)
            break
        except TooManyRequests as e:
            print "Maximum Request Reached! Wating for Next Hour..."
            time.sleep(60) # retry after 1 min
            continue
        except BehanceException as e:
            print "BehanceException: ", str(e)
            numExceptions = numExceptions+1
            break
    for rev_id in wip["revisions"].keys():
        print "====== Revision ID:", rev_id
        while True:
            try:
                comments = u.get_revision_comments(revision_id=rev_id)
                if len(comments)==0:
                    break;

                for comment in comments:
                    # avoid duplicate
                    if visitedComments.has_key(comment["id"]):
                        continue
                    visitedComments[["id"]] = comment
                    dbcomments.insert(json.loads(json.dumps(comment), object_hook=remove_dot_key))
                    numComments +=1
                print "====== Revision ID, Comments = ", rev_id, ", ", numComments
            except TooManyRequests as e:
                print "Maximum Request Reached! Wating for Next Hour..."
                time.sleep(60) # retry after 1 min
                continue
            except BehanceException as e:
                print "BehanceException: ", str(e)
        numExceptions = numExceptions+1
                break

print "Total comments, Wips =  ", numComments, ", ", numWips
