import sys, os, urllib, csv, urlparse, time


# for each project
with open(sys.argv[1], 'rb') as csvfile:
    projReader = csv.reader(csvfile)
    next(projReader)
    for row in projReader:
        projID          = row[0]
        # projName        = row[2]
        projImageURL    = row[2]
        ext = os.path.splitext(urlparse.urlparse(projImageURL).path)[1]
        print "retrieving",projID+ext
        if os.path.exists('./new-images/'+projID+".jpg"):
            print 'file exists.'
            continue
        if projImageURL != None:
            urllib.urlretrieve(projImageURL, './images/'+projID+ext)
            time.sleep(0.01)
# determine image name and extention
