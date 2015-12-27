import os, json

def find_index(lst, key, value):
	for i, dic in enumerate(lst):
		if dic[key] == value:
			return i
	return -1

price_files = sorted(map(lambda x: str('ccc/')+x, os.listdir('ccc')))
coins = {}
for f in price_files:
	g = f.replace('ccc/','').replace('.json','').split('-')
	if len(g) == 3 or (len(g) == 4 and g[3] == 'c'):
		if g[0] not in coins:
			coins[g[0]] = {'btc': [], 'ltc': []}
		if g[1] == 'btc':
			coins[g[0]]['btc'].append(g[2])
		if g[1] == 'ltc':
			coins[g[0]]['ltc'].append(g[2])
to_del = []
for coin in coins:
	if len(coins[coin]['btc']) == 0 or len(coins[coin]['ltc']) == 0:
		to_del.append(coin)
for d in to_del:
	del(coins[d])
del(to_del)
print 'coin, market, proportional difference'
for coin in coins:
	markets = coins[coin]['btc']
	if 'cryptsy' in markets:
		coin_name = coin
		cryptsy = json.load(open(str('ccc/'+coin+'-btc-cryptsy.json')))
		if len(markets) > 1:
			coin = {market: json.load(open(str('ccc/'+coin+'-btc-'+market+'.json'))) for market in markets if market != 'cryptsy'}
			for market in coin:
				for price in coin[market]:
					try:
						i = find_index(cryptsy, 'date', price['date'])
					except KeyError:
						i = -1
					if i != -1:
						print ', '.join([coin_name, market, price['date'], str((price['price']-cryptsy[i]['price'])/cryptsy[i]['price'])])
		else:
			print ', NaN, NaN, NaN'

						
'''
			for price in btc:
				try:
					i = find_index(ltc, 'date', price['date'])
				except KeyError:
					i = -1
				if i != -1:
					pass'''
