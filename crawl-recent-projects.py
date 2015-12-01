import os, pymongo, sys, csv, datetime, threading, json
from behance_python.api import API
from behance_python.exceptions \
    import TooManyRequests, InternalServerError, BehanceException
from behance_python.behance import Behance
interval = 10 # seconds
pageNum = 1 # start with one
maxProjects = 1200
numProjects = 0
# set API key
key = raw_input('Input your Behance API key: ');
behance = API(key)

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance
dbcol       = db.recent_projects
dbcol.remove({}) # clear existing db collection

# collect 1800 (= 12 * 150/hr, est.1h) projects
def crawl_recent_projects(dbcol, pageNum, interval, numProjects, maxProjects):
    print "Sending a Request at " + datetime.datetime.now().strftime("%I:%M%p on %B %d, %Y")
    try:
        projects = behance.project_search("", sort="published_date", page=pageNum)
        if len(projects)==0:
            print "End of Page Reached! - page:", pageNum
            return
        numProjects = numProjects+len(projects)
        if numProjects>maxProjects:
            return
        #save into mongo db
        print "Page Num: ", pageNum
        for project in projects: # remove integer keys that exist in the returned results
            dbcol.insert({ "page": pageNum, "project": json.loads(json.dumps(project.copy()))} )
        pageNum = pageNum + 1  # increas page number
    except InternalServerError as e:
        print "End of Page Reached! - page:", pageNum
        return
    except TooManyRequests as e:
        print "Maximum Request Reached! Wating for Next Hour..."
    except BehanceException as e:
        print "BehanceException!"
        return
    threading.Timer(interval, crawl_recent_projects, \
        [dbcol, pageNum, interval, numProjects, maxProjects]).start()

crawl_recent_projects(dbcol, pageNum, interval, numProjects, maxProjects)
