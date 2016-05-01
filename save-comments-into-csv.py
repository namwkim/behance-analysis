import os, pymongo, sys, csv, datetime, threading, json, random, time
import urllib2

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

db_prj_cmts = db.sample_project_comments
db_wip_cmts = db.sample_wip_comments

# header
header = [
    "comment"
]

# project comments 
print 'saving project comments'
with open("behance-project-comments.csv", 'wb') as csvfile:
    csvwriter = csv.writer(csvfile);
    csvwriter.writerow(header)
    i = 0
    for comment in db_prj_cmts.find():
        # print "processing", prj_cmt["id"], "(",i,")","..."
        i=i+1
        record = [
            comment["comment"]
        ]
        record 	=[ s.encode('utf-8') if isinstance(s, unicode) else s for s in record]
        csvwriter.writerow(record)
    print 'total project comments:', i

# project comments 
print 'saving wip comments'
with open("behance-wips-comments.csv", 'wb') as csvfile:
    csvwriter = csv.writer(csvfile);
    csvwriter.writerow(header)
    i = 0
    for comment in db_wip_cmts.find():
        # print "processing", prj_cmt["id"], "(",i,")","..."
        i=i+1
        record = [
            comment["comment"]
        ]
        record  =[ s.encode('utf-8') if isinstance(s, unicode) else s for s in record]
        csvwriter.writerow(record)
    print 'total wip comments:', i
