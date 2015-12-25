import json, urllib2, csv
from bs4 import BeautifulSoup
import argparse
import os
import re

parser = argparse.ArgumentParser(description='dataprocess')
parser.add_argument("output_dir")
args = parser.parse_args()


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
  symbol = coin['name']
  name = coin['Name']
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

  # fix announcement url
  if ann and 'bitcointalk.org' in ann:
    url = ann
    # remove msg#msg from the end
    m = re.search(r'msg\d+#msg\d+$', url)
    if m is not None:
      url = re.sub(r'msg\d+#msg\d+$', '', url)
    
    # remove msg from the end
    m = re.search(r'msg\d+$', url)
    if m is not None:
      url = re.sub(r'msg\d+$', '', url)

    # remove #new from end
    m = re.search(r'new#new$', url)
    if m is not None:
      url = re.sub(r'new#new$', '', url)
    m = re.search(r'new$', url)
    if m is not None:
      url = re.sub(r'new$', '', url)
  
    # if url does not end with .0, add one to end of topic number 
    m = re.search(r'\.$', url)
    if m is not None:
      url = re.sub(r'\.$', '.0', url)

    # if end misses .0, add it
    m = re.search(r'[1-9]$', url)
    if m is not None:
      url = re.sub(r'$', '.0', url)
    
    # remove ;all from the end
    m = re.search(r';all$', url)
    if m is not None:
      url = re.sub(r';all$', '', url)

    ann = url

  processed_list.append([str(symbol), str(name), str(children_amount), str(algorithm), str(technical), str(premine), str(pos)])		
  processed_list_ann.append([str(symbol), str(name), str(ann)])
#	processed_list.append({'symbol': name, 'children_amount': children_amount, 'algorithm': algorithm, 'technical': technical, 'premine':premine, 'pos':pos, 'pow':pow_})


if not os.path.exists(args.output_dir):
  os.makedirs(args.output_dir)

with open(os.path.join(args.output_dir, 'technicality.csv'),'wb') as csvfile:
  csvfile.write(str(','.join(['symbol', 'name', 'children_amount', 'algorithm', 'technical', 'premine', 'pos'])+'\n'))
  for coin in processed_list:
    csvfile.write(str(','.join(coin)+'\n'))

with open(os.path.join(args.output_dir, 'ann_mapofcoins.csv'),'wb')as csvfile:
  csvfile.write(str(','.join(['symbol', 'name', 'ann'])+'\n'))
  for coin in processed_list_ann:
    csvfile.write(str(','.join(coin)+'\n'))
