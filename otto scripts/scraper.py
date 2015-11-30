import csv
import urllib2, json
import operator
from pprint import pprint
from bs4 import BeautifulSoup
import os
from os import path
import sys
import ast
###ccc = cryto coin charts
###cmc = coin market cap
def get_prices_cmc(basecoin):
	print 'Getting cmc prices for', basecoin
	priceurl = 'http://coinmarketcap.com/datapoints/'+basecoin+'/price_btc/'
	volumeurl = 'http://coinmarketcap.com/datapoints/'+basecoin+'/volume/'
	print priceurl
	try:
		prices = ast.literal_eval(str(urllib2.urlopen(priceurl).read()))
		volumes = ast.literal_eval(str(urllib2.urlopen(volumeurl).read()))
	#	pricevolumes = []
	#	for price in prices:
	#		for volume in volumes:
	#			if price[0] == volume[0]:
	#				pricevolumes.append({'price':float(price[1]), 'volume':int(volume[1]), 'date':volume[0]})
	#	return pricevolumes
		return prices
	except:
		pass

def scrape_coins_cmc():
	print 'Scraping cmc coins'
	url = 'http://coinmarketcap.com/all/views/all/'
	html = urllib2.urlopen(url).read()
	soup = BeautifulSoup(html, 'html.parser')
	tr = soup.findAll('tr')
	coins = {}
	for i, c in enumerate(tr):
		print str(int(i+1)),'of',len(tr)
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

def scrape_markets_cmc(coin):
	print 'Scraping cmc markets'
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

def get_prices_ccc(basecoin, paircoin, market, period, resolution):
	print 'Getting ccc prices for', basecoin, paircoin, market
	url = 'http://www.cryptocoincharts.info/fast/period.php?pair='+basecoin+'-'+paircoin+'&market='+market+'&time='+period+'&resolution='+resolution	
	prices = urllib2.urlopen(url).read().replace('[[','').replace(']]','').split('],[') #Formatea correctamente el archivo
	for price in prices:
		price = price.split(',')
		try:
			yield {'date': price[0], 'price': float(price[1]), 'low': float(price[2]), 'open': float(price[3]), 'close': float(price[4]), 'high': float(price[5]), 'volume': float(price[6]) }
		except IndexError:
			yield {}

def find_index(lst, key, value):
	for i, dic in enumerate(lst):
		if dic[key] == value:
			return i
	return -1

def scrape_coins_ccc():
	print 'Scraping CCC'
	url = 'http://www.cryptocoincharts.info/coins/info/1001'
	html = urllib2.urlopen(url).read()
	soup = BeautifulSoup(html, 'html.parser')
	trlist = soup.findAll('tr')
	coins = {}
	for i, tr in enumerate(trlist):
		print str(int(i+1))
		try:
			a = tr.find('td').a
			name = tr.findAll('td')[1].text
			coin_url = str('http://www.cryptocoincharts.info'+a['href'])
			coin_html = urllib2.urlopen(coin_url).read()
			coin_soup = BeautifulSoup(coin_html, 'html.parser')
			coin_table = coin_soup.findAll('table',{'class': 'table table-striped'})
			coin_tr = coin_table[1].find('tbody').findAll('tr')
			coin_markets = []
			for ctr in coin_tr:
				market_td = ctr.findAll('td')
				coin_markets.append({'market':market_td[0].text, 'pair':market_td[1].text, 'link': str('http://www.cryptocoincharts.info' + market_td[1].a['href'])})
			coins[a.text] = {'markets':coin_markets, 'name':name}
		except AttributeError:
			pass
	return coins

def get_csvs_recursive(directory_path):
	files = []
	for x in os.listdir(directory_path):
		if '.csv' in x and '_severity' not in x:
			files.append(os.path.join(directory_path, x))
		if os.path.isdir(os.path.join(directory_path, x)):
			files = files + get_csvs_recursive(os.path.join(directory_path, x))
	return files
try:
	parameter = int(sys.argv[1])
except:
	parameter = 0

if parameter == 1 or parameter == 5:
	ccc_coins = scrape_coins_ccc()
	cmc_coins = scrape_coins_cmc()
	with open('ccc_coins.json','wb') as js:
		json.dump(ccc_coins, js)
	with open('cmc_coins.json','wb') as js:
		json.dump(cmc_coins, js)
	with open('prices/coinsymbol-ccc.csv','wb') as csvfile:
		csvfile.write('name, symbol\n')
		for coin in ccc_coins:
			csvfile.write(str(ccc_coins[coin]['name']+', '+ coin +'\n'))
	with open('prices/coinsymbol-cmc.csv','wb') as csvfile:
		csvfile.write('name, symbol\n')
		for coin in cmc_coins:
			csvfile.write(str(cmc_coins[coin]['coin_name']+', '+ coin +'\n'))

if parameter == 2 or parameter == 5:
	with open('ccc_coins.json','rb') as ccc_coins:
		ccc_coins = json.load(ccc_coins)
		for coin in ccc_coins:
			for row in ccc_coins[coin]['markets']:
				if row['link'] is not '':
					split = row['link'].split('/')
					prices = list(get_prices_ccc(split[4], split[5], split[6], 'alltime', '1h'))
					with open(str('prices/ccc/'+'-'.join([split[4], split[5], split[6]])+'.json'),'wb') as price_file:
						json.dump(prices, price_file)

if parameter == 3 or parameter == 5:
	with open('cmc_coins.json', 'rb') as cmc_coins:
		cmc_coins = json.load(cmc_coins)
		for coin in cmc_coins:
			prices = get_prices_cmc(cmc_coins[coin]['slug'])
			with open(str('prices/cmc/'+cmc_coins[coin]['slug']+'-btc.json'),'wb') as price_file:
				json.dump(prices, price_file)

if parameter == 4 or parameter == 5:
	ccc_jsons = ['prices/ccc/' + x for x in os.listdir('prices/ccc')]
	cmc_jsons = ['prices/cmc/' + x for x in os.listdir('prices/cmc')]
	with open('cmc_coins.json', 'rb') as cmc_coins:
		cmc_coins = json.load(cmc_coins)
	with open('prices/coinsymbol-cmc.csv','wb') as csvfile:
		csvfile.write('name, symbol, first_price_date\n')
		for i, coin in enumerate(cmc_coins):
			print '\r', 'Processing',str(int(i+1)) , 'of', len(cmc_coins),
			with open(str('prices/cmc/'+cmc_coins[coin]['slug']+'-btc.json'),'rb') as price_file:
				price_list = json.load(price_file)
			try:
				first_price_date = str(int(min(price_list, key=lambda x: x[0])[0])/1000)
			except ValueError:
				first_price_date = 'NaN'
			csvfile.write(str(cmc_coins[coin]['coin_name'] + ', '+ coin+ ', ' + first_price_date +'\n'))
	with open('prices/coinsymbol-ccc.csv','wb') as csvfile:
		csvfile.write('name, symbol, first_price_date\n')
		with open('ccc_coins.json', 'rb') as json_file:
			ccc_coins = json.load(json_file)
		for i, coin in enumerate(ccc_coins):
			print '\r', 'Processing',str(int(i+1)) , 'of', len(ccc_coins),
			for row in ccc_coins[coin]['markets']:
				first_price_list = []
				if row['link'] is not '':
					split = row['link'].split('/')
					with open(str('prices/ccc/'+'-'.join([split[4], split[5], split[6]])+'.json'),'rb') as price_file:
						try:
							first_price_list.append(json.load(price_file)[0]['date'].replace('\"', ''))
						except KeyError, AttributeError:
							first_price_list.append('NaN')
			csvfile.write(str(ccc_coins[coin]['name']+', '+ coin + ', ' + ', '.join(first_price_list) +'\n'))
if parameter > 5 or parameter < 1:
	print 'Options are:\n\t1 for generating coin json files\n\t2 for getting ccc prices (requires coin json file to be generated first)\n\t3 for getting cmc prices (requires coin json file to be generated first)\n\t4 for adding first_price_date to CSVs (requires fetched prices)\n\t5 for running everything'
