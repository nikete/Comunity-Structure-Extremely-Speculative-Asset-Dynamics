#!/usr/bin/python

import argparse
import itertools
import sys
import os
import math
import csv

parser = argparse.ArgumentParser(description='dataprocess')
parser.add_argument("bitcoin_forum_input",
                    help="The location of file containing posts from bitcoin forum.")
parser.add_argument("altcoin_forum_input",
                    help="The location of file containing posts from alternative coins forum.")
parser.add_argument("coin_names_input",
                    help="The location of file containing the names and abbreviation of all alt "
                    "coins.")
parser.add_argument("output",
                    help="The location where output file containing both bitcoin and alternative "
                    "posts will be written to.")
parser.add_argument("--verbose", help="Print verbose output",
                    action="store_true", default=False)
args = parser.parse_args()

if __name__ == '__main__':
    if not os.path.isfile(args.bitcoin_forum_input):
        sys.exit('Could not find bitcoin forum input file %s.' % args.bitcoin_forum_input)
    if not os.path.isfile(args.altcoin_forum_input):
      sys.exit('Could not find altcoin forum input file %s.' % args.altcoin_forum_input)
    if not os.path.isfile(args.coin_names_input):
        sys.exit('Could not find coin names input file %s.' % args.coin_names_input)

    coin_names = dict()
    with open(args.coin_names_input, mode='r') as infile:
        reader = csv.reader(infile)
        coin_names = {rows[0]:rows[1] for rows in reader}
        infile.close()
   
    # Generate header columns
    header = ["forum_id", "subject_id", "post_id", "forum_page", "subject_page", "num_replies",
              "num_views", "url", "started_by", "user", "user_level", "user_activity", "date",
              "time"]
    for coin in coin_names:
        header.append(coin)

    # prepare output file and write header to output
    output_dir = os.path.dirname(args.output)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    output_file = open(args.output, 'w')
    csvwriter = csv.writer(output_file, delimiter=',')
    csvwriter.writerow(header)

    # process bitcoin input data
    with open(args.bitcoin_forum_input, mode='r') as infile:
        forum_id = 1
        reader = csv.reader(infile)
        next(reader, None)  # skip the headers
        for input_row in reader:
            num_replies = input_row[0]
            url = input_row[1]
            forum_page = input_row[2]
            num_views = input_row[3]
            started_by = input_row[4]
            content = input_row[5]
            post_id = input_row[6]
            user_level = input_row[7]
            user = input_row[8]
            time = input_row[9]
            date = input_row[10]
            user_activity = input_row[11]
            subject_id = input_row[12]
            subject_page = input_row[13]
            subject = input_row[14]
            
            # Generate output row to output file
            output_row = [forum_id, subject_id, post_id, forum_page, subject_page, num_replies,
                          num_views, url, started_by, user, user_level, user_activity, date, time]
            # now iterator through coins
            for coin, coin_name in coin_names.iteritems():
                str1 = (" " + coin + " ").lower()
                str2 = (" " + coin_name + " ").lower()
                if (str1 in content.lower() or
                    str2 in content.lower() or
                    str1 in subject.lower() or
                    str2 in subject.lower()):
                    output_row.append(1)
                else:
                    output_row.append(0)
            csvwriter.writerow(output_row)
        infile.close()
    
    # similarly process altcoin input data
    with open(args.altcoin_forum_input, mode='r') as infile:
        forum_id = 2
        reader = csv.reader(infile)
        next(reader, None)  # skip the headers
        for input_row in reader:
            num_replies = input_row[0]
            url = input_row[1]
            forum_page = input_row[2]
            num_views = input_row[3]
            started_by = input_row[4]
            content = input_row[5]
            post_id = input_row[6]
            user_level = input_row[7]
            user = input_row[8]
            time = input_row[9]
            date = input_row[10]
            user_activity = input_row[11]
            subject_id = input_row[12]
            subject_page = input_row[13]
            subject = input_row[14]
            
            # Generate output row to output file
            output_row = [forum_id, subject_id, post_id, forum_page, subject_page, num_replies,
                          num_views, url, started_by, user, user_level, user_activity, date, time]
            # now iterator through coins
            for coin, coin_name in coin_names.iteritems():
                str1 = (" " + coin + " ").lower()
                str2 = (" " + coin_name + " ").lower()
                if (str1 in content.lower() or
                    str2 in content.lower() or
                    str1 in subject.lower() or
                    str2 in subject.lower()):
                    output_row.append(1)
                else:
                    output_row.append(0)
            csvwriter.writerow(output_row)
        infile.close()
    
    output_file.close()

