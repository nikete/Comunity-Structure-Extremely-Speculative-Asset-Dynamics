#!/usr/bin/python

import argparse
import os
import csv

parser = argparse.ArgumentParser(
    description="This scripts adds commas to end of rows with misssing values for "
                "columns")
parser.add_argument("network_input_file",
                    help="Location of file containing by network metrics.")
parser.add_argument("output_file",
                    help="Location of output file with joined results.")

args = parser.parse_args()

def separate_by_coin_fields(row):
  coin = row[0]
  network_date = row[1]
  other_fields = list()
  for i in range(2, len(row)):
    other_fields.append(row[i])
  return (coin, network_date, other_fields)


def main():
  # map from date to metrics
  by_date_metrics = dict()
  # map from coin to metrics
  metrics = dict()

  # read by date info
  input_file = open(args.network_input_file, 'r')
  input_reader = csv.reader(input_file, delimiter = ',')
  input_header = input_reader.next()
  num_fields = len(input_header)
  
  output_file = open(args.output_file, 'w')
  csvwriter = csv.writer(output_file, delimiter=',')
  csvwriter.writerow(input_header)
  for row in input_reader:
    row.extend(['']*(num_fields - len(row)))
    csvwriter.writerow(row)
  input_file.close()
  output_file.close()
  


if __name__ == '__main__':
  main()
