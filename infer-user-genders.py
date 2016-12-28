import os, pymongo, sys, csv, urllib2, json, time
from urllib2 import quote

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

# fetch users
dbusers     = db.users
users = []
for user in dbusers.find():
    if user.has_key('gender')==False:
        users.append(user)

# construct country code map
countryCode = {}
with open("country-codes.csv", 'rb') as csvfile:
    rows = csv.reader(csvfile)
    next(rows)
    for row in rows:
        countryCode[row[1].replace(" ", "").replace(",", "").lower()] = row[0]

# genders
def check_error(data):
    if data.has_key('errno'):
        raise Exception("Error: " + str(data['errno']) + " - "+ data['errmsg'])
def update(user, gender, accuracy):
    print 'saving gender: ', user["username"], " - ", gender, "(", accuracy, ")"
    print ': ', user["url"]
    db.users.update_one(
    { "id": user['id']}, {"$set":{ "gender": gender } })

# set API key
apikey = raw_input('Input Gender API (https://gender-api.com) key: ');

for user in users:
    country = user["country"].replace(" ", "").replace(",", "").lower()
    try:
        name = quote(user["first_name"].encode('utf-8'))
        size = len(user["first_name"].replace(" ", ""))
        if size==0 or size==1:
            update(user, "unknown", 0)
            continue
        print name.replace(" ", "")
        if countryCode.has_key(country):
            print "1. requesting", user["first_name"], ",", countryCode[country]
            data = json.load(urllib2.urlopen("https://gender-api.com/get?key=" + apikey \
            + "&name="+name+ "&country="+countryCode[country]))
            check_error(data)
            if data['accuracy']<90:
                data = json.load(urllib2.urlopen("https://gender-api.com/get?key=" + apikey \
                + "&name="+name))
                check_error(data)
                if data['accuracy']>=95:
                    update(user, data['gender'], data['accuracy'])
                else:
                    update(user, "unknown", data['accuracy'])
            else:
                update(user, data['gender'], data['accuracy'])
            data['accuracy']
        else:
            print "2. requesting", user["first_name"], ",", country
            data = json.load(urllib2.urlopen("https://gender-api.com/get?key=" + apikey \
            + "&name="+name))
            check_error(data)
            if data['accuracy']>=95:
                update(user, data['gender'], data['accuracy'])
            else:
                update(user, "unknown", data['accuracy'])
    except Exception as e:
         print e
         break
