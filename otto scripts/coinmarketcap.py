# -*- coding: utf-8 -*-
# <nbformat>3.0</nbformat>

# <codecell>

import urllib2
import csv
from bs4 import BeautifulSoup
import re
import ast
import operator
from time import strftime
from datetime import datetime

# <codecell>

def find_index(lst, key, value):
    for i, dic in enumerate(lst):
        if dic[key] == value:
            return i
    return -1

# <codecell>

def get_prices(basecoin):
    priceurl = 'https://api.coinmarketcap.com/v1/datapoints/'+basecoin+'/'
    try:
        prices = ast.literal_eval(urllib2.urlopen(priceurl).read())
        pricevolumes = []
        for a,b,c in zip(prices['price_usd'], prices['volume_usd'], prices['price_btc']):
            if a[1] == 0:
                volume = 0
            else:
                volume = b[1]/a[1]
            pricevolumes.append({'date': a[0], 'usd': a[1], 'btc': c[1], 'volume': volume})
    except:
        pass
    pricevolumes = sorted(pricevolumes, key = lambda k:k['date'])
    return pricevolumes

# <codecell>

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

# <codecell>

def scrape_markets(coin):
    url = str('http://coinmarketcap.com/currencies/'+ coin +'/#markets')
    try:
        html = urllib2.urlopen(url).read()
    except:
        return []
    soup = BeautifulSoup(html, 'html.parser')
    tr = soup.findAll('tr')
    markets = []
    for c in tr:
        if len(c.findAll('td')) == 7:
            market = c.findAll('td')[1].text
            markets.append(market)
    return markets

# <codecell>

def analyze_prices(prices, markets, pair):
    coin = {}
    if len(prices) > 0:
        max_price = max(prices, key = operator.itemgetter(pair))[pair]
        min_price = min(prices, key = operator.itemgetter(pair))[pair]
        index_max = find_index(prices, 'btc', max_price)
        average = sum(map(lambda x: x[pair],prices))/len(prices)
        average_after_max = sum(map(lambda x: x[pair],prices[index_max:]))/len(prices)
        active_days = (int(prices[-1]['date']/1000)-int(prices[0]['date']/1000))/86400
        min_price_after_max = min(prices[index_max:], key = operator.itemgetter(pair))[pair]
        last_price = prices[-1][pair]
        if index_max > 0:
            active_days_before_max = (int(prices[index_max]['date']/1000)-int(prices[0]['date']/1000))/86400
        else:
            active_days_before_max = 0
        try:
            average_volume_weighted = sum(map(lambda x: x[pair]*x['volume'],prices))/sum(map(lambda x: x['volume'],prices))
            average_volume_weighted_after_max = sum(map(lambda x: x[pair]*x['volume'],prices[index_max:]))/sum(map(lambda x: x['volume'],prices[index_max:]))
        except ZeroDivisionError, UnboundLocalError:
            average_volume_weighted = 0
            average_volume_weighted_after_max = 0
            
        total_volume = sum(map(lambda x: x['volume'],prices))
        total_volume_before_max = sum(map(lambda x: x['volume'],prices[:index_max-1])) 
        market_num = len(markets)
        try:
            severity_to_min_price = max_price/min_price
        except ZeroDivisionError, UnboundLocalError:
            severity_to_min_price = 'NaN'
        try:
            severity_to_min_price_after_max = max_price/min_price_after_max
        except ZeroDivisionError, UnboundLocalError:
            severity_to_min_price_after_max = 'NaN'
        try:
            severity_to_last = max_price/last_price
        except ZeroDivisionError, UnboundLocalError:
            severity_to_last = 'NaN'
        try:
            severity_to_average = max_price/average
        except ZeroDivisionError, UnboundLocalError:
            severity_to_average = 'NaN'
        try:
            severity_to_average_after_max = max_price/average_after_max
        except ZeroDivisionError, UnboundLocalError:
            severity_to_average_after_max = 'NaN'
        try:
            severity_to_average_volume_weighted = max_price/average_volume_weighted
        except ZeroDivisionError, UnboundLocalError:
            severity_to_average_volume_weighted = 'NaN'
        try:
            severity_to_average_after_max_volume_weighted = max_price/average_volume_weighted_after_max
        except ZeroDivisionError, UnboundLocalError:
            severity_to_average_after_max_volume_weighted = 'NaN'
        try:
            normalized_total_volume = total_volume/active_days
        except ZeroDivisionError, UnboundLocalError:
            normalized_total_volume = 'NaN'
        try:
            normalized_total_volume_before_max = total_volume_before_max/active_days_before_max
        except ZeroDivisionError, UnboundLocalError:
            normalized_total_volume_before_max = 'NaN'
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
        coin['normalized_total_volume'] = normalized_total_volume
        coin['normalized_total_volume_before_max'] = normalized_total_volume_before_max

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
    return coin

        

# <codecell>

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
'normalized_total_volume',
'normalized_total_volume_before_max',
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

# <codecell>

coins = scrape_coins()

# <codecell>

btc_analysis = []
usd_analysis = []
for coin in coins:
    for pair in ['usd','btc']:
        prices = get_prices(coins[coin]['slug'])
        markets = scrape_markets(coins[coin]['slug'])
        analysis = analyze_prices(prices, markets, 'btc')
        result = analysis.copy()
        result.update({'symbol': coin})
        result.update(coins[coin])
        if pair == 'btc':
            btc_analysis.append(result)
        if pair == 'usd':
            usd_analysis.append(result)
      

# <codecell>

print usd_analysis

# <codecell>

with open('fullusd.csv','wb') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames)
    writer.writeheader()
    for coin in usd_analysis:
        writer.writerow(coin)
with open('fullbtc.csv','wb') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames)
    writer.writeheader()
    for coin in btc_analysis:
        writer.writerow(coin)

# <codecell>


# <codecell>


# <codecell>


