import json, urllib2, csv
from bs4 import BeautifulSoup

with open('mapofcoins.json') as jsonfile:
	coins = json.load(jsonfile)

def coin_travel(coin, coinlist):
	if 'children' in coin.keys():
		coinlist.append(coin)
		for c in coin['children']:
			coin_travel(c, coinlist)
	else:
		coinlist.append(coin)

coinlist = []
coin_travel(coins['coins'], coinlist)
processed_list = []
for coin in coinlist:
	if coin['PoS'] == 'no':
		pos = False
	else:
		pos = True
	if coin['Premine'] == None or str(coin['Premine']).lower() == 'no':
		premine = False
	else:
		premine = True
	pow_ = coin['PoW']
	technical = False
	name = coin['name']
	if 'children' in coin.keys():
		children_amount = len(coin['children'])
	else:
		children_amount = 0
	algorithm = coin['algo']
	if 'ForkedFrom' in coin.keys():
		if coin['ForkedFrom'] != '':
			for c in coinlist:
				if coin['ForkedFrom'] == c['name']:
					if c['algo'] != coin['algo']:
						technical = True
	processed_list.append([str(name), str(children_amount), str(algorithm), str(technical), str(premine), str(pos)])		
#	processed_list.append({'symbol': name, 'children_amount': children_amount, 'algorithm': algorithm, 'technical': technical, 'premine':premine, 'pos':pos, 'pow':pow_})
fieldnames = [
'symbol',
'children_amount',
'algorithm',
'technical',
'premine',
'pos',
'pow'
]
with open('technicality.csv','wb') as csvfile:
	csvfile.write(str(','.join(['name', 'children_amount', 'algorithm', 'technical', 'premine', 'pos'])+'\n'))
	for coin in processed_list:
		csvfile.write(str(', '.join(coin)+'\n'))
