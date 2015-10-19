f = open('data/forumAND.csv')
AND = f.readlines()
f.close()
f = open('data/forumOR.csv')
OR = f.readlines()
f.close()
result = 0
for line in AND:
	line  = line.split(',')
	for row in OR:
		row = row.split(',')
		if row[0] == line[0] and row[3] != line[3]:
			result += 1
print result
