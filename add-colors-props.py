import os, pymongo, sys, csv, datetime


# print filename

prop_file = csv.reader(open("./data/colors-100.csv", 'r'))
props_header 	= next(prop_file)
props_map 		= {}
print 'construct a property map.'
for row in prop_file:
	projID, ext = os.path.splitext(row[0])
	props_map[projID] = row

print 'Add color properties to projects'
proj_file = csv.reader(open("./data/projects-100.csv", 'r'))
proj_header = next(proj_file)

output_file = csv.writer(open('./data/projects-colors-100.csv', 'wb'))
output_file.writerow(proj_header + props_header[3:])
nodata = 0
total  = 0
for row in proj_file:
	if props_map.has_key(row[0])==False:
		# print 'no prop found:', row[0]
		# output_file.writerow(row + ["NA"]*len(props_header[3:]))
		nodata += 1
	else:
		props = props_map[row[0]]
		if props[3]=="N/A" or props[4]=="N/A":
			# print 'error in prop:', row[0]
			# output_file.writerow(row + ["NA"]*len(props_header[3:]))
			nodata += 1
		else:
			output_file.writerow(row + map(float,props[3:]))
			total += 1


print 'missing data:', nodata
print 'total data', total
