import os, sys
from PIL import Image

exts = {'.gif': True, '.png': True, '.jpg': True, '.jpeg': True};
avgWidth  = 174
avgHeight = 127
for root, dirs, files in os.walk("./new-images"):
	i = 1
	for file in files:
		if file.startswith('.'):
			continue
		name, ext = os.path.splitext(file)
		# if exts.has_key(ext)==False:
		# 	exts[ext] = True
		print 'processing (',i,'):',file
		i+=1
		try:

			im = Image.open("./new-images/"+file)
			newSize = (400, int(400.0/im.size[0]*im.size[1]))
			im = im.convert('RGB').resize(newSize)
			im.save("./new-images/"+name+".jpg")
			# avgWidth 	= avgWidth + float(im.size[0]-avgWidth)/i
			# avgHeight 	= avgHeight + float(im.size[1]-avgHeight)/i
		except IOError as detail:
			print detail
			# os.remove("./images/"+file)
		except IndexError as detail:
			print detail
			# os.remove("./images/"+file)
		except:
			print 'Unexpected Error...'
			# os.remove("./images/"+file)
	# print "avgWidth", avgWidth
	# print "avgHeight", avgHeight
# print exts
