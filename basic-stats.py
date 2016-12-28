import os, pymongo, sys, csv, datetime, threading, json, random, time

import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import numpy as np

json_data=open(os.path.expanduser('~/.plotly/.credentials')).read()
auth = json.loads(json_data)
plotly.tools.set_credentials_file(username=auth['username'], api_key=auth['api_key'])


# db connection
localClient = pymongo.MongoClient('localhost', 27017)
db          = localClient.behance

dbusers     = db.users
dbprojects  = db.projects
dbappreciations = db.appreciations

# users
degrees = []
outdegrees = []
indegrees = []
degrees_real = []
i = 0
nodes = []
users = []
for node in db.users.find():
    print i
    i+=1
    followee_counts = db.links.count({'follower_id':node['id']})
    follower_counts = db.links.count({'followee_id':node['id']})
    # print 'add node:',node['id'], node['username']
    degrees.append(followee_counts+follower_counts)
    indegrees.append(follower_counts)
    outdegrees.append(followee_counts)

    degrees_real.append(node['stats']['followers']+node['stats']['following'])
    nodes.append({'node':node['id'], 'username':node['username'],
        'outdegree': followee_counts, 'indegree': follower_counts,
        'degree': followee_counts+follower_counts})
    users.append(node)

sorted_nodes = sorted(nodes, key=lambda x: x['degree'])
sorted_users = sorted(users, key=lambda x: x['stats']['followers']+x['stats']['following'])

print 'nodes'
print map(lambda x: x['username'], sorted_nodes[1:10])
print 'users'
print map(lambda x: x['username'], sorted_users[1:10])

py.plot([go.Histogram(x=degrees)])
py.plot([go.Histogram(x=degrees_real)])
py.plot([go.Histogram(x=indegrees)])
py.plot([go.Histogram(x=outdegrees)])

# projects



# appreciations
