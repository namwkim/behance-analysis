import os, pymongo, sys, csv, datetime, threading, json, random, time
from behance_python.api import API
from behance_python.exceptions \
    import TooManyRequests, InternalServerError, BehanceException
from behance_python.behance import Behance

def remove_dot_key(obj):
    for key in obj.keys():
        new_key = key.replace(".","")
        if new_key != key:
            obj[new_key] = obj[key]
            del obj[key]
    return obj

# seed
random.seed("90948148")

# total users 1,500,000
maxUsers        = 50000
maxSteps        = 1000 # graph cadinality n is not available

# set API key
key = raw_input('Input your Behance API key: ');
behance = API(key)

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance
seedUsers   = [user['user'] for user in db.seed_users.find()]

print "Size of Seed Pool: ", len(seedUsers)

dbusers     = db.sample_users
dbusers.remove({}) # clear existing db collection
dbfollowing     = db.sample_users_following
dbfollowing.remove({}) # clear existing db collection
dbfollowers     = db.sample_users_followers
dbfollowers.remove({}) # clear existing db collection

visitedUsers = {} # contained ids of visited users (To avoid duplicates in DB)
visitedFollowers = {}
visitedFollowed  = {}
curStep = 0

# randomly pick a starting user
startUser = random.sample(seedUsers, 1)[0]

curUser = startUser
# input: curUser
while len(visitedUsers)<maxUsers:
    curStep =  curStep + 1 # increase step
    print "STEP, USERS = ", curStep, ", ", len(visitedUsers)
    try:
        # get the user basic information
        if visitedUsers.has_key(curUser["id"]) == True:
            print "VISITED USER: ", curUser["username"]
            userProfile = visitedUsers[curUser["id"]]
        else:
            userProfile = behance.get_user(curUser["id"])
            # save the user info if not saved before (check with visitedUsers)
            print "NEW USER: ", curUser["username"]
            visitedUsers[curUser["id"]] = userProfile
            dbusers.insert(json.loads(json.dumps(userProfile.copy()),\
                object_hook=remove_dot_key))


        # with the probability of 0.15, decide to go back to the starting node
        prob = random.random()
        if prob <= 0.15:
            print "RESTART: Going back to the starting user (prob = 0.15)."
            curUser = startUser
            continue

        # if the number of steps is greater than the jump threshold,
        #   choose a different starting node.
        links = userProfile["stats"]["following"] + userProfile["stats"]["followers"]

        if curStep>maxSteps or links==0:
            seedUsers.remove(startUser)
            if len(seedUsers)==0:
                print "ERROR: ran out of seed users!"
                break
            print "NEWWALK: Choosing a different starting user."
            startUser = random.sample(seedUsers, 1)[0]
            curUser = startUser
            curStep = 0
            continue

        # pick whether to use the following list of the list of followers
        side = random.choice([1, 2]) # 1: following list , 2: followers

        # randomly select a page number
        print "FOLLOWING, FOLLOWER: ", userProfile["stats"]["following"], ", ", \
                                        userProfile["stats"]["followers"]
        if side==1:
            pageSize = userProfile["stats"]["following"]
            if pageSize == 0:
                side = 0
                pageSize = userProfile["stats"]["followers"]
        else:
            pageSize = userProfile["stats"]["followers"]
            if pageSize == 0:
                side = 1
                pageSize = userProfile["stats"]["following"]
        # if pageSize == 0: This should not be possible.

        pageSize = pageSize/12 if pageSize%12==0 else pageSize/12+1
        pageNum  = random.randint(1, pageSize)

        # HACK: it seems like there is a limit for the page number ~ 400
        pageNum = 400 if pageNum>400 else pageNum
        # retrieve the connected user list
        if side==1:
            if visitedFollowed.has_key(curUser['id'])==True:
                print "GET FOLLOWED-SAVED. page = ", pageNum
                connectedUsers = visitedFollowed[curUser['id']]
            else:
                print "GET FOLLOWED. page = ", pageNum
                connectedUsers = userProfile.get_following(page=pageNum)
                visitedFollowed[curUser["id"]] = connectedUsers
                dbfollowing.insert({ 'userid': curUser['id'], 'following': json.loads(\
                json.dumps(connectedUsers), object_hook=remove_dot_key)})
        else:
            if visitedFollowers.has_key(curUser['id'])==True:
                print "GET FOLLOWERS-SAVED. page = ", pageNum
                connectedUsers = visitedFollowers[curUser['id']]
            else:
                print "GET FOLLOWERS. page = ", pageNum
                connectedUsers = userProfile.get_followers(page=pageNum)
                visitedFollowers[curUser["id"]] = connectedUsers
                dbfollowers.insert({ 'userid': curUser['id'], 'followers': json.loads(\
                json.dumps(connectedUsers), object_hook=remove_dot_key)})

        if len(connectedUsers)==0: # just in case
            print "ERROR: No candidates for the next user"
            curStep = curStep - 1
            continue
    except TooManyRequests as e:
        print "Maximum Request Reached! Wating for Next Hour..."
        time.sleep(60) # retry after 1 min
        curStep = curStep - 1
        continue
    except BehanceException as e:
        print "BehanceException: ", str(e)
        break

    # randomly select a next user from the list
    curUser = random.sample(connectedUsers, 1)[0]
