import json, urllib2, csv
from bs4 import BeautifulSoup

with open('mapofcoinsbtc.json') as jsonfile:
	btccoins = json.load(jsonfile)
with open('mapofcoinsnxt.json') as jsonfile:
	ripplecoins = json.load(jsonfile)
with open('mapofcoinsripple.json') as jsonfile:
	nxtcoins = json.load(jsonfile)
with open('mapofcoinsbytecoin.json') as jsonfile:
	bytecoins = json.load(jsonfile)



def coin_travel(coin, coinlist):
	if 'children' in coin.keys():
		coinlist.append(coin)
		for c in coin['children']:
			coin_travel(c, coinlist)
	else:
		coinlist.append(coin)

coinlist = []
coin_travel(btccoins['coins'], coinlist)
coin_travel(ripplecoins['coins'], coinlist)
coin_travel(nxtcoins['coins'], coinlist)
coin_travel(bytecoins['coins'], coinlist)
processed_list = []
processed_list_ann = []
for coin in coinlist:
	if coin['PoS'] == 'no':
		pos = 0
	else:
		pos = 1
	if coin['Premine'] == None or str(coin['Premine']).lower() == 'no':
		premine = 0
	else:
		premine = 1
	if 'PoW' in coin.keys():
		pow_ = coin['PoW']
	else:
		pow_ = ''
	technical = 0
	name = coin['name']
	if 'children' in coin.keys():
		children_amount = len(coin['children'])
	else:
		children_amount = 0
	if 'algo' in coin.keys():
		algorithm = coin['algo']
	else:
		algo = ''
	if 'ForkedFrom' in coin.keys():
		if coin['ForkedFrom'] != '':
			for c in coinlist:
				if coin['ForkedFrom'] == c['name']:
					if 'algo' in c.keys() and 'algo' in coin.keys():
						if c['algo'] != coin['algo']:
							technical = 1
					elif 'algo' in c.keys() or 'algo'in coin.keys():
							technical = 1
		else:
			technichal = 1
	if 'ANN'in coin.keys():
		ann = coin['ANN']
	else:
		ann = ''
	processed_list.append([str(name), str(children_amount), str(algorithm), str(technical), str(premine), str(pos)])		
	processed_list_ann.append([str(name), str(ann)])
#	processed_list.append({'symbol': name, 'children_amount': children_amount, 'algorithm': algorithm, 'technical': technical, 'premine':premine, 'pos':pos, 'pow':pow_})


with open('technicality.csv','wb') as csvfile:
	csvfile.write(str(','.join(['symbol', 'children_amount', 'algorithm', 'technical', 'premine', 'pos'])+'\n'))
	for coin in processed_list:
		csvfile.write(str(', '.join(coin)+'\n'))

with open('ann_mapofcoins.csv','wb')as csvfile:
	csvfile.write(str(','.join(['symbol','ann'])+'\n'))
	for coin in processed_list_ann:
		csvfile.write(str(','.join(coin)+'\n'))


