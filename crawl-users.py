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
max_users        = 50000
max_steps        = 1000 # graph cadinality n is not available

# set API key
key = raw_input('Input your Behance API key: ');
behance = API(key)

# db connection
db_client = pymongo.MongoClient('localhost', 27017)
db          = db_client.behance
seed_users   = []
for user in db.seed_users.find():
    user = user['user']
    num_links = user["stats"]["following"] + user["stats"]["followers"]
    if num_links>5:
        seed_users.append(user)

print "Size of Seed Pool: ", len(seed_users)

dbusers = db.users
dbusers.drop_indexes()
dbusers.remove({}) # clear existing db collection
dblinks = db.links
dblinks.remove({}) # clear existing db collection
# dbcache = db.user_caches # need to manually refressh


users = {} # contained ids of users users (To avoid duplicates in DB)
visited_links = {}
follower_links = {}
followed_links  = {}

# cache
# for cache in dbcache.find():
#     key = cache['key']
#     value = cache['value']
#     if cache['type']=='user':
#         users[key] = value
#     elif cache['type']=='link':
#         visited_links[key] = value
#     elif cache['type']=='follower_links':
#         follower_links[key] = value
#     elif cache['type']=='followed_links':
#         followed_links[key] = value

cur_step = 0
page_size = 12

FOLLOWED = 1
FOLLOWER = 2
# randomly pick a starting user
start_user = random.sample(seed_users, 1)[0]
cur_user = start_user
pre_user = None
pre_users = []
# input: cur_user
while True:
    cur_step =  cur_step + 1 # increase step
    print '=========== Current Step:',cur_step
    pre_user = None if len(pre_users)==0 else pre_users[-1]
    print "STEP, USERS = ", cur_step, ", ", len(users)
    try:
        # get the user basic information
        if users.has_key(cur_user["id"]) == True:
            print "VISITED USER: ", cur_user["username"], cur_user["id"]
            user_profile = users[cur_user["id"]]
        else:
            print "NEW USER: ", cur_user["username"], cur_user["id"]
            user_profile = behance.get_user(cur_user["id"])
            # save the user info if not saved before (check with users)
            users[cur_user["id"]] = user_profile
            dbusers.insert(json.loads(json.dumps(user_profile.copy()),
                object_hook=remove_dot_key))
            # cache
            # dbcache.insert({'type':'user', 'key':str(cur_user['id']),
            #     'value':json.loads(json.dumps(user_profile.copy()),\
            #     object_hook=remove_dot_key)})

        # create a link
        if pre_user!=None and side==FOLLOWED:
            key = str(pre_user['id']) + str(cur_user['id'])
            if visited_links.has_key(key)==False:
                print 'CREATE FOLLOWED LINK (', pre_user['id'], cur_user['id'],')'
                dblinks.insert({ 'follower_id': pre_user['id'], 'followee_id': cur_user['id']})
                # dbcache.insert({'type':'link', 'key':key, 'value':True})
                visited_links[key] = True
            else:
                print 'VISITED FOLLOWED LINK (', pre_user['id'], cur_user['id'],')'
        elif pre_user!=None and side==FOLLOWER:
            key = str(cur_user['id']) + str(pre_user['id'])
            if visited_links.has_key(key)==False:
                print 'CREATE FOLLOWING LINK (', cur_user['id'], pre_user['id'],')'
                dblinks.insert({ 'follower_id': cur_user['id'], 'followee_id': pre_user['id']})
                # dbcache.insert({'type':'link', 'key':key, 'value':True})
                visited_links[key] = True
            else:
                print 'VISITED FOLLOWING LINK (', cur_user['id'], pre_user['id'],')'

        if len(users)>=max_users:
            break
        # with the probability of 0.15, decide to go back to the starting node
        # or if there is no outgoing link
        links = user_profile["stats"]["following"] + user_profile["stats"]["followers"]
        prob = random.random()
        if prob <= 0.15 or links<5:
            print "RESTART: Going back to the starting user (prob = 0.15)."
            # start_user = random.sample(seed_users, 1)[0]
            cur_user = start_user
            pre_users = []
            continue

        # if the number of steps is greater than the jump threshold,
        #   choose a different starting node.
        if cur_step>max_steps:
            print "RANDOM JUMP: Choosing a different starting user."
            # seed_users.remove(start_user)
            # if len(seed_users)==0:
            #     print "ERROR: ran out of seed users!"
            #     break
            start_user = random.sample(seed_users, 1)[0]
            cur_user = start_user
            pre_users = []
            cur_step = 0 # reset step
            continue

        # pick whether to use the following list of the list of followers
        side = random.choice([1, 2]) # 1: following list , 2: followers

        # randomly select a page number
        print "FOLLOWING, FOLLOWER: ", user_profile["stats"]["following"], ", ", \
                                        user_profile["stats"]["followers"]
        if side==FOLLOWED:
            numLinks = user_profile["stats"]["following"]
            if numLinks == 0:
                side = 0
                numLinks = user_profile["stats"]["followers"]
        else:
            numLinks = user_profile["stats"]["followers"]
            if numLinks == 0:
                side = 1
                numLinks = user_profile["stats"]["following"]
        # if numLinks == 0: This should not be possible.

        numLinks = numLinks/page_size if numLinks%page_size==0 else numLinks/page_size+1
        page_num  = random.randint(1, numLinks)

        # HACK: it seems like there is a limit for the page number ~ 400
        page_num = 400 if page_num>400 else page_num
        # retrieve the connected user list
        key = str(cur_user['id'])+','+str(page_num)
        if side==FOLLOWED:
            if followed_links.has_key(key)==True:
                print "GET FOLLOWEES-VISITED. page = ", page_num
                links = followed_links[key]
            else:
                print "GET FOLLOWEES. page = ", page_num
                links = user_profile.get_following(page=page_num)
                # dbcache.insert({'type':'followed_links', 'key':key, 'value':links})
                followed_links[key] = links
        else:
            if follower_links.has_key(key)==True:
                print "GET FOLLOWERS-VISITED. page = ", page_num
                links = follower_links[key]
            else:
                print "GET FOLLOWERS. page = ", page_num
                links = user_profile.get_followers(page=page_num)
                # dbcache.insert({'type':'follower_links', 'key':key, 'value':links})
                follower_links[key] = links
        if len(links)==0: # just in case
            print "ERROR: No candidates for the next user"
            cur_step = cur_step - 1
            continue
    except TooManyRequests as e:
        print "Maximum Request Reached! Wating for Next Hour..."
        time.sleep(60) # retry after 1 min
        cur_step = cur_step - 1
        continue
    except BehanceException as e:
        print "BehanceException: ", str(e)
        time.sleep(2) # retry after 1 min
        # start_user = random.sample(seed_users, 1)[0]
        # go back to the start user
        cur_user = start_user
        pre_users = []
        continue

    # randomly select a next user from the list
    # pre_user = cur_user
    pre_users.append(cur_user)
    cur_user = random.sample(links, 1)[0]
