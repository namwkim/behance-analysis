import os, pymongo, sys, csv, datetime, threading, json, random, time
import urllib2

# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

dbprojects = db.projects


# print filename
with open("./sampled-graph/behance-projects.csv", 'wb') as csvfile:
    projwriter = csv.writer(csvfile);

    header = [
        "id",
        "name",
        "url",
        "published_on",
        "created_on",
        "fields",
        "views",
        "appreciations",
        "comments",
        "num_owners",
        "authors",
        "occuations",
        "countries"
    ]
    projwriter.writerow(header)

    # loop over projects
    i = 0
    for project in dbprojects.find():
        print "processing", project["id"], "(",i,")","..."
        i=i+1
        # derived project authors' countries, occupation
        authors     = []
        occupations = []
        countries   = []
        for user in project["owners"]:
            countries.append(user["country"])
            occupations.append(user["occupation"])
            authors.append(user["username"])

        if isinstance(project["covers"], list) or project["covers"]["original"]==None:
            print 'url is not found:', project["covers"]
            continue
        record = [
            project["id"],
            project["name"],
            project["covers"]["original"],
            project["published_on"],
            project["created_on"], # estimated
            "|".join(project["fields"]),
            project["stats"]["views"],         # project views
            project["stats"]["appreciations"], # project appreciates
            project["stats"]["comments"], # project comments
            len(project["owners"]),
            "|".join(authors),
            "|".join(occupations),
            "|".join(countries)
        ]
        record 	=[ s.encode('utf-8') if isinstance(s, unicode) else s for s in record]
        projwriter.writerow(record)
