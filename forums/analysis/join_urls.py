#!/usr/bin/python

import argparse
import collections
import csv
import os
import sys
import pandas

parser = argparse.ArgumentParser(
    description='This script joins candidate urls from several lists.')
parser.add_argument('candidate_urls', nargs='+',
                    help='Multiple csv files, each containing the following introduction '
                    'information per coin: symbol,name,earliest_trade_date,'
                    'earliest_mention_date,user1,user1_url1,user1_date1')
parser.add_argument('-e', '--exclude_coins', dest='exclude_coins', default='',
                    help='Optional file of the same format as candidate_urls. If '
                    'specified coins in this list are excluded from the output.')
parser.add_argument('output_file',
                    help='Location of output file. It will have the same format at '
                    'candidate urls with the exception that it will have multiple urls.')
args = parser.parse_args()

if __name__ == '__main__':
  excluded_coins = set()
  if args.exclude_coins:
    df = pandas.read_csv(args.exclude_coins, index_col=0)
    excluded_coins = set(df.index.values)

  dfs = []
  all_coins = set()
  all_coins_to_name = dict()
  all_coins_to_earliest_trade_date = dict()
  for input_file in args.candidate_urls:
    df = pandas.read_csv(input_file, index_col=0)
    all_coins = all_coins.union(set(df.index.values))
    dfs.append(df)
    all_coins_to_name.update(df['name'].to_dict())
    all_coins_to_earliest_trade_date.update(df['earliest_trade_date'].to_dict())

  included_coins = all_coins.difference(excluded_coins)
  
  csvwriter = csv.writer(open(args.output_file, 'w'), delimiter=',')
  header = ['symbol', 'name', 'earliest_trade_date']
  header.extend(['url' + str(i) for i in range(1,len(args.candidate_urls)+1)])
  csvwriter.writerow(header)
  for coin in included_coins:
    name = all_coins_to_name[coin]
    earliest_trade_date = all_coins_to_earliest_trade_date[coin]
    output_row = [coin, name, earliest_trade_date]
    for df in dfs:
      url = ''
      if coin in df.index:
        url = df.loc[coin, 'user1_url1']
      output_row.append(url)
    csvwriter.writerow(output_row)


