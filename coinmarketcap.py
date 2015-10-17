import csv
import urllib2, json
import operator
from pprint import pprint
from bs4 import BeautifulSoup
import os
from os import path
import re
import ast
from time import strftime
from datetime import datetime

def get_prices(basecoin):
	priceurl = 'http://coinmarketcap.com/datapoints/'+basecoin+'/price_btc/'
	volumeurl = 'http://coinmarketcap.com/datapoints/'+basecoin+'/volume/'
	try:
		prices = ast.literal_eval(urllib2.urlopen(priceurl).read())
		volumes = ast.literal_eval(urllib2.urlopen(volumeurl).read())
		pricevolumes = []
		for price in prices:
			for volume in volumes:
				if price[0] == volume[0]:
					pricevolumes.append({'price':float(price[1]), 'volume':int(volume[1]), 'date':volume[0]})
		return pricevolumes
	except:
		pass		

def find_index(lst, key, value):
	for i, dic in enumerate(lst):
		if dic[key] == value:
			return i
	return -1

def scrape_coins():
	url = 'http://coinmarketcap.com/all/views/all/'
	html = urllib2.urlopen(url).read()
	soup = BeautifulSoup(html, 'html.parser')
	tr = soup.findAll('tr')
	coins = {}
	for c in tr:
		try:
			symbol = c.find('td',{'class':'text-left'}).text
			slug = c.find('td', {'class':'no-wrap currency-name'}).a['href']
			unique_name = slug.replace('currencies','').replace('/','').replace('assets','').lower()
			url2 = 'http://coinmarketcap.com' + slug
			html2 = urllib2.urlopen(url2).read()
			soup2 = BeautifulSoup(html2, 'html.parser')
			coins[symbol] = {'slug': unique_name, 'coin_name':soup2.find('h1',{'class':'text-large'}).text.rstrip().lstrip().split(' (')[0]}
		except AttributeError:
			pass
	return coins

def scrape_markets(coin):
	url = str('http://coinmarketcap.com/currencies/'+ coin +'/#markets')
	html = urllib2.urlopen(url).read()
	soup = BeautifulSoup(html, 'html.parser')
	tr = soup.findAll('tr')
	markets = []
	for c in tr:
		if len(c.findAll('td')) == 7:
			market = c.findAll('td')[1].text
			markets.append(market)
	return markets

def get_csvs_recursive(directory_path):
	files = []
	for x in os.listdir(directory_path):
		if '.csv' in x and '_severity' not in x:
			files.append(os.path.join(directory_path, x))
		if os.path.isdir(os.path.join(directory_path, x)):
			files = files + get_csvs_recursive(os.path.join(directory_path, x))
	return files

def analyze_coin(coin):
	try:
		prices = sorted(list(get_prices(coin['slug'])), key = lambda k:k['date'])
		print coin
		markets = scrape_markets(coin['slug'])
		max_price = max(prices, key = operator.itemgetter('price'))['price']
		min_price = min(prices, key = operator.itemgetter('price'))['price']
		index_max = find_index(prices, 'price', max_price)
		min_price_after_max = (min(prices[index_max:], key = operator.itemgetter('price'))['price'])
		last_price = prices[-1]['price']
		average = sum(map(lambda x: x['price'],prices))/len(prices)
		average_after_max = sum(map(lambda x: x['price'],prices[index_max:]))/len(prices[index_max:])
		try:
			average_volume_weighted = sum(map(lambda x: x['price']*x['volume'],prices))/sum(map(lambda x: x['volume'],prices))
			average_volume_weighted_after_max = sum(map(lambda x: x['price']*x['volume'],prices[index_max:]))/sum(map(lambda x: x['volume'],prices[index_max:]))
		except ZeroDivisionError:
			average_volume_weighted = 0
			average_volume_weighted_after_max = 0
		total_volume = sum(map(lambda x: x['volume'],prices))
		market_num = len(markets)
		try:
			severity_to_min_price = max_price/min_price
		except ZeroDivisionError:
			severity_to_min_price = 'NaN'
		try:
			severity_to_min_price_after_max = max_price/min_price_after_max
		except ZeroDivisionError:
			severity_to_min_price_after_max = 'NaN'
		try:
			severity_to_last = max_price/last_price
		except ZeroDivisionError:
			severity_to_last = 'NaN'
		try:
			severity_to_average = max_price/average
		except ZeroDivisionError:
			severity_to_average = 'NaN'
		try:
			severity_to_average_after_max = max_price/average_after_max
		except ZeroDivisionError:
			severity_to_average_after_max = 'NaN'
		try:
			severity_to_average_volume_weighted = max_price/average_volume_weighted
		except ZeroDivisionError:
			severity_to_average_volume_weighted = 'NaN'
		try:
			severity_to_average_after_max_volume_weighted = max_price/average_volume_weighted_after_max
		except ZeroDivisionError:
			severity_to_average_after_max_volume_weighted = 'NaN'
		coin['severity_to_min_price'] = severity_to_min_price
		coin['max_price'] = max_price
		coin['min_price'] = min_price
		coin['severity_to_min_price_after_max'] = severity_to_min_price_after_max
		coin['severity_to_last'] = severity_to_last
		coin['severity_to_average'] = severity_to_average
		coin['severity_to_average_after_max'] = severity_to_average_after_max
		coin['severity_to_average_volume_weighted'] = severity_to_average_volume_weighted
		coin['severity_to_average_after_max_volume_weighted'] = severity_to_average_after_max_volume_weighted
		coin['total_volume'] = total_volume
		coin['market_num'] = market_num
		coin['first_trade'] = datetime.fromtimestamp(int(prices[0]['date']/1000)).strftime('%Y-%m-%d')
		if 'BTC-E' in markets:
			coin['BTC-E'] = True
		else:
			coin['BTC-E'] = False
		if 'Kraken' in markets:
			coin['Kraken'] = True
		else:
			coin['Kraken'] = False
		if 'Poloniex' in markets:
			coin['Poloniex'] = True
		else:
			coin['Poloniex'] = False
		if 'Cryptsy' in markets:
			coin['Cryptsy'] = True
		else:
			coin['Cryptsy'] = False
		if 'BTC38' in markets:
			coin['BTC38'] = True
		else:
			coin['BTC38'] = False
		if 'BTER' in markets:
			coin['BTER'] = True
		else:
			coin['BTER'] = False
		if 'Bittrex' in markets:
			coin['Bittrex'] = True
		else:
			coin['Bittrex'] = False
	except TypeError, IndexError:
		pass
	return coin

fieldnames = [
'symbol',
'slug',
'coin_name',
'max_price',
'min_price',
'severity_to_min_price',
'severity_to_min_price_after_max',
'severity_to_last','severity_to_average',
'severity_to_average_after_max',
'severity_to_average_volume_weighted',
'severity_to_average_after_max_volume_weighted',
'total_volume',
'market_num',
'BTC-E',
'Kraken',
'Poloniex',
'Cryptsy',
'BTC38',
'BTER',
'Bittrex',
'first_trade',
]
fieldnames_modified_to_be_unique = [
'symbol',
'coin_name'
]
fieldnames_unmodified = [
'symbol',
'coin_name'
]
fieldnames_coindata = [
'symbol',
'coin_name',
'slug'
]
coins = []
#coins = scrape_coins()
with open('coindata.csv') as csvfile:
	reader = csv.DictReader(csvfile)
	for coin in reader:
		coins.append(coin)

'''
with open('coindata.csv','wb') as csvfile:
	writer = csv.DictWriter(csvfile, fieldnames_coindata)
	writer.writeheader()
	for coin in coins:
		writer.writerow({'symbol': coin, 'slug': coins[coin]['slug'], 'coin_name':coins[coin]['coin_name']})
'''
'''
with open('modified.csv', 'wb') as csvfile:
	writer = csv.DictWriter(csvfile, fieldnames_modified_to_be_unique)
	writer.writeheader()
	for coin in coins:
		writer.writerow({'symbol': coin, 'coin_name': coins[coin]['slug']})

with open('unmodified.csv', 'wb') as csvfile:
	writer = csv.DictWriter(csvfile, fieldnames_unmodified)
	writer.writeheader()
	for coin in coins:
		writer.writerow({'symbol': coin, 'coin_name': coins[coin]['coin_name']})
'''

for i, coin in enumerate(coins):
	print i+1, 'of', len(coins)
	coin = analyze_coin(coin)

with open('full.csv','wb') as csvfile:
	writer = csv.DictWriter(csvfile, fieldnames)
	writer.writeheader()
	for coin in coins:
		writer.writerow(coin)
'''
with open('coinmarketanalisis.csv', 'wb') as csv:
	csv.write('coin, '+', '.join(buffer_['coin'])+'\n')
	for coin in buffer_:
		if coin is not 'coin':
			csv.write(str(coin+ ', '+', '.join(map(lambda x: str(x), buffer_[coin]))+'\n'))
'''
