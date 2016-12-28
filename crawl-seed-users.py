import os, pymongo, sys, csv, datetime, threading, json
from behance_python.api import API
from behance_python.exceptions \
    import TooManyRequests, InternalServerError, BehanceException
from behance_python.behance import Behance
interval = 1 # 10 seconds
page_num = 1 # start with one
# max_projs = 20 # 1200
# curr_proj = 0
# set API key
key = raw_input('Input your Behance API key: ');
behance = API(key)

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db    = localClient.behance
dbcol = db.seed_users
dbcol.remove({}) # clear existing db collection

# collect 1800 (= 12 * 150/hr, est.1h) projects
max_seed_users = 500 # unlikely to reach this number (will reach max page first)
seed_users = []
def crawl_recent_projects():
    global page_num, interval
    print "Sending a Request at " + datetime.datetime.now().strftime("%I:%M%p on %B %d, %Y")
    try:
        projects = behance.project_search("", sort="published_date", page=page_num)
        if len(projects)==0:
            print "End of Page Reached! - page:", page_num
            return
        #save into mongo db
        print "Timeline Page Num: ", page_num
        for project in projects:
            for user in project.owners:
                if user.id in seed_users or \
                    len(seed_users)>=max_seed_users: #save unique users up to max
                    continue
                print "Saving...", user.username
                dbcol.insert({ "user": json.loads(json.dumps(user.copy()))})
                seed_users.append(user.id)
        page_num = page_num + 1  # increas page number
        if len(seed_users)>=max_seed_users:
            return
    except InternalServerError as e:
        print "End of Page Reached! - page:", page_num
        return
    except TooManyRequests as e:
        print "Maximum Request Reached! Wating for Next Hour..."
    except BehanceException as e:
        print "BehanceException!"
        return
    threading.Timer(interval, crawl_recent_projects).start()

crawl_recent_projects()

print "# of users saved: ", len(seed_users)
