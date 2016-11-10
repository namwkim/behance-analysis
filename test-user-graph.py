
import os, pymongo, sys
import networkx as nx
import matplotlib.pyplot as plt

G=nx.DiGraph()

# db connection
db_client = pymongo.MongoClient('localhost', 27017)
db          = db_client.behance
# nodes = [user for user in db.users.find()]
nodes = []
i = 0
for node in db.users.find():
    print i
    i+=1
    followee_links = db.links.count({'follower_id':node['id']})
    follower_links = db.links.count({'followee_id':node['id']})
    print 'add node:',node['id'], node['username']
    nodes.append({'node':node['id'], 'username':node['username'],
        'followee': followee_links, 'follower': follower_links})

print sorted(nodes, key=lambda x: x['followee']+x['follower'])



#
# for node in db.users.find():
#     print 'add node:',node['id'], node['username']
#     # G.add_node(node['id'], username=node['username'])
#     # followed users
#     followee_links = db.links.find({'follower_id':node['id']})
#     # for link in followee_links:
#     #     G.add_edge(node['id'], link['followee_id'])
#
#     # follower users
#     follower_links = db.links.find({'followee_id':node['id']})
#     # for link in follower_links:
#     #     G.add_edge(node['id'], link['followee_id'])
#
# # labels=dict((n,d['username']) for n,d in G.nodes(data=True))
# # nx.draw(G, pos=nx.spring_layout(G), labels = labels)
# # plt.show()
#
# nodes = []
# for node in G.nodes(data=True):
#     nodes.append((node[1]['username'],G.out_degree(node[0])))
#
# sorted_nodes = sorted(nodes, key=lambda x: x[1])
# print sorted_nodes
# degree_sequence=sorted(nx.degree(G).values(),reverse=True)
# print degree_sequence
# plt.hist(degree_sequence)
# plt.title("Degree distribution")
# plt.ylabel("degree")
# plt.xlabel("rank")
# plt.show()
