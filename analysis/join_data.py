#!/usr/bin/python

import argparse
import itertools
import os
import csv
import sys
import collections
import igraph
import datetime
import operator
import pandas

parser = argparse.ArgumentParser(
    description='Joins the network metrics with price metrics. Uses first network metric '
    'file. Falls back on remaining files in order.')
parser.add_argument('price_metric_file',
                    help='The location of CSV file containing price metrics.')
parser.add_argument('trivialness_file',
                    help='The location of CSV file containing trivialness.')
parser.add_argument('network_metric_files', nargs='+',
                    help='The location of CSV file containing network metrics.')
parser.add_argument('output_file',
                    help='Location of joined output csv file.')
args = parser.parse_args()

if __name__ == '__main__':
  price_metrics = pandas.read_csv(args.price_metric_file, sep = ',')
  trivialness = pandas.read_csv(args.trivialness_file, sep = ',')
  all_network_metrics = list()
  for network_file in args.network_metric_files:
    all_network_metrics.append(pandas.read_csv(network_file, sep = ','))

  price_joined_networks = None
  for network_metrics in all_network_metrics:
    joined = pandas.merge(price_metrics,
                          network_metrics,
                          how='inner',
                          left_on='symbol',
                          right_on='coin')
    joined = pandas.merge(joined,
                          trivialness,
                          how='inner',
                          left_on='symbol',
                          right_on='coin')
    if price_joined_networks is None:
      price_joined_networks = joined
    else:
      joined_coins = set(price_joined_networks['symbol'])
      new_coins = set(joined['symbol'])
      missing_coins = new_coins - joined_coins
      missing_rows = joined[joined['symbol'].isin(missing_coins)]
      price_joined_networks = price_joined_networks.append(missing_rows)
      print 'Added ' + str(len(missing_coins)) + ' missing coins to joined data'
    
    joined_coins = set(joined['symbol'])
    price_coins = set(price_metrics['symbol'])
    network_coins = set(network_metrics['coin'])
    
    print 'There were ' + str(len(price_coins)) + ' coins in price file'
    print 'There were ' + str(len(network_coins)) + ' coin in network file'
    print 'Joined ' + str(len(joined_coins)) + ' coins'
    print ''

  price_columns = list(price_metrics.columns.values)
  network_columns = list(all_network_metrics[0].columns.values)
  trivial_columns = list(trivialness.columns.values)
  columns_to_write = price_columns
  columns_to_write.extend(network_columns)
  columns_to_write.extend(trivial_columns)
  columns_to_write = [x for x in columns_to_write
                      if x not in ['coin', 'coin_x', 'coin_y', 'slug']]
  price_joined_networks.to_csv(args.output_file, index=False, columns = columns_to_write)

