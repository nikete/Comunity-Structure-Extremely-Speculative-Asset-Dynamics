#!/usr/bin/python

import argparse
import collections
import csv
import os
import sys
import pandas

parser = argparse.ArgumentParser(
    description='This script joins introducer info from several lists.')
parser.add_argument('introducers', nargs='+',
                    help='Multiple csv files, each containing the introduction '
                    'information per coin. If the same coins appears in multiple '
                    'files, the one in which appears first will be written to the '
                    'output; so the order matters.')
parser.add_argument('output_file',
                    help='Location of output file. It will have the same format at '
                    'candidate urls with the exception that it will have multiple urls.')
args = parser.parse_args()

if __name__ == '__main__':
  dfs = []
  all_coins = set()
  for input_file in args.introducers:
    df = pandas.read_csv(input_file, index_col=0)
    # remove rows/coins that were already in previous data frames
    coins_to_remove = all_coins.intersection(set(df.index.values))
    print 'removing rows ' + str(coins_to_remove)
    df.drop(coins_to_remove, inplace = True)
    all_coins = all_coins.union(set(df.index.values))
    dfs.append(df)

  output_df = pandas.concat(dfs)
  output_df.to_csv(args.output_file)

