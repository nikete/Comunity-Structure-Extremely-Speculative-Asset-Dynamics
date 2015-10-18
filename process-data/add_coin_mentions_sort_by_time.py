#!/usr/bin/python

import argparse
import itertools
import sys
import os
import math
import csv
import collections
import nltk

parser = argparse.ArgumentParser(description='A script that goes through crawled data '
                                 'from different forums (i.e bitcoin, altcoin ...) and '
                                 'extracts relevant information from each post and '
                                 'finally sorts all the posts by datetime.')
parser.add_argument('forum_inputs', nargs='+',
                    help='The location of file(s) containing posts from (different) '
                    'forum(s).')
parser.add_argument('modified_coin_names_input',
                    help='The location of file containing the names and abbreviation of '
                    'all alt coins, that are modified to be distinct. First mentioned '
                    'coins field is checked against these strings.')
parser.add_argument('unmodified_coin_names_input',
                    help='The location of file containing the names and abbreviation of '
                    'all alt coins in their original form. Second mentioned coins field '
                    'is checked against these strings.')
parser.add_argument('output',
                    help='The location where output file containing both bitcoin and '
                    'alternative posts sorted by time and coin mentions will be written '
                    'to.')
parser.add_argument('-mms', '--modified_mention_scheme',
                    dest='modified_mention_scheme', default='sc,nORs',
                    choices=['s,nORs', 's,nANDs', 'c,nORs', 'c,nANDs',
                             'sc,nORs', 'sc,nANDs'],
                    help='Determines how we decide whether a modified coin string is '
                    'mentioned in the post. There are two parts to the scheme which must '
                    'be concatenated with a comma. The first part determine in which '
                    'parts of the post to look for coin name/symbol: in subject, in '
                    'content or in their concatenation? s denotes subject and c denotes '
                    'conent. So possible options for first part are s,c and sc where in '
                    'the last one subject and content are treated as a single string. ' 
                    'The second part determines which modified string representations of '
                    'the coin to look for in the post portions determined by first part: '
                    'either modified name or modified symbol or both modified name and '
                    'modified symbol. Note that in contrast to first part of the scheme '
                    'we cannot look for only one of name or symbols since that usecase '
                    'is not relevant to our application. n denotes name and s denotes '
                    'symbol. So possible options for second part are nORs,nANDs. When '
                    'we are looking for mentions of EITHER name OR symbol, we add a '
                    'space character around name and symbol to minimize the chances of '
                    'wrong matches against parts of a larger string.')
parser.add_argument('-ums', '--unmodified_mention_scheme',
                    dest='unmodified_mention_scheme', default='sc,nANDs',
                    choices=['s,nORs', 's,nANDs', 'c,nORs', 'c,nANDs',
                             'sc,nORs', 'sc,nANDs'],
                    help='Determines how we decide whether an unmodified coin string is '
                    'mentioned in the post. There are two parts to the scheme which must '
                    'be concatenated with a comma. The first part determine in which '
                    'parts of the post to look for coin name/symbol: in subject, in '
                    'content or in their concatenation? s denotes subject and c denotes '
                    'conent. So possible options for first part are s,c and sc where in '
                    'the last one subject and content are treated as a single string. ' 
                    'The second part determines which unmodified string representations '
                    'of the coin to look for in the post portions determined by first '
                    'part: either unmodified name or unmodified symbol or both '
                    'unmodified name and unmodified symbol. Note that in contrast to '
                    'first part of the scheme we cannot look for only one of name or '
                    'symbols since that usecase is not relevant to our application. n '
                    'denotes name and s denotes symbol. So possible options for second '
                    'part are nORs,nANDs. When we are looking for mentions of EITHER '
                    'name OR symbol, we add a space character around name and symbol to '
                    'minimize the chances of wrong matches against parts of a larger '
                    'string.')
parser.add_argument('-es', '--extra_strings', dest='extra_strings', default='',
                    help='A comma-separated list of extra strings that must be present '
                    'in the search string addition to coin name/symbol for a mention to '
                    'be valid. Note that search string is determined by the first part '
                    'of mms/ums flags (i.e. subject, content or their concatenation). '
                    'The extra strings are applied to both unmodified and modified '
                    'mention scheme.')
args = parser.parse_args()

def parse_mention_scheme(mention_scheme):
  mention_scheme_post = mention_scheme.split(',')[0]
  mention_scheme_coin = mention_scheme.split(',')[1]
  
  search_subject = True if 's' in mention_scheme_post else False
  search_content = True if 'c' in mention_scheme_post else False

  both_name_and_symbol = True if mention_scheme_coin == 'nANDs' else False
  return (search_subject, search_content, both_name_and_symbol)

def extract_mentioned_coins(coin_names, content, subject, extra_strings,
                            search_subject, search_content, both_name_and_symbol):
  mentioned_coins = list()
  # extra strings that must be present for a mention to be counted. but don't keep empty
  # strings
  extra_strings = extra_strings.lower()
  extra_strings_list = [x.strip() for x in extra_strings.split(',') if x]
  for coin, coin_name in coin_names.iteritems():
    symbol = coin.lower()
    name = coin_name.lower()
    # determine the string to search within. Add spaces between two strings, so they will
    # be tokenized correctly.
    search_string = ''
    if search_subject and search_content:
      search_string = subject + ' ' + content
    elif search_subject:
      search_string = subject
    elif search_content:
      search_string = content

    search_tokens = nltk.tokenize.wordpunct_tokenize(search_string.lower())

    # first check coin strings are mentioned
    coin_string_mentioned = False
    if both_name_and_symbol:
      coin_string_mentioned = all(x in search_tokens for x in [symbol, name])
    else:
      coin_string_mentioned = any(x in search_tokens for x in [symbol, name])

    # now check extra strings are mentioned
    if (coin_string_mentioned and
        all(x in search_tokens for x in extra_strings_list)):
      mentioned_coins.append(coin)

  return mentioned_coins


if __name__ == '__main__':
  for forum_input in args.forum_inputs:
    if not os.path.isfile(forum_input):
      sys.exit('Could not find forum input file %s.' % forum_input)

  if not os.path.isfile(args.modified_coin_names_input):
    sys.exit('Could not find modified coin names input file %s.'
             % args.modified_coin_names_input)
  if not os.path.isfile(args.unmodified_coin_names_input):
    sys.exit('Could not find unmodified coin names input file %s.'
             % args.unmodified_coin_names_input)

  modified_coin_names = dict()
  with open(args.modified_coin_names_input, mode='r') as infile:
    reader = csv.reader(infile)
    modified_coin_names = {rows[0]:rows[1] for rows in reader}
    infile.close()

  unmodified_coin_names = dict()
  with open(args.unmodified_coin_names_input, mode='r') as infile:
    reader = csv.reader(infile)
    unmodified_coin_names = {rows[0]:rows[1] for rows in reader}
    infile.close()

  # parse coin mention schemes
  (modified_search_subject,
   modified_search_content,
   modified_both_name_and_symbol) = parse_mention_scheme(args.modified_mention_scheme)
  (unmodified_search_subject,
   unmodified_search_content,
   unmodified_both_name_and_symbol) = parse_mention_scheme(args.unmodified_mention_scheme)

  # Generate header columns
  header = ["forum_id", "subject_id", "post_id", "forum_page", "subject_page",
            "num_replies", "num_views", "url", "started_by", "user", "user_level",
            "user_activity", "date", "time",
            "mentioned_modified_coins", "mentioned_unmodified_coins"]


  # this dictionary will hold all the data, not sorted though
  # The value is a list, because it's possible for many posts to share the same timestamp
  posts_keyed_by_timestamp = collections.defaultdict(list)
  # process bitcoin input data
  num_posts = 0
  forum_id = 0
  for input_file in args.forum_inputs:
    print("Adding posts from " + input_file)
    with open(input_file, mode='r') as infile:
      # modify forum_id as we are reading a different file now
      forum_id += 1
      reader = csv.reader(infile)
      next(reader, None)  # skip the headers
      for input_row in reader:
        num_posts += 1
        if (num_posts % 100000 == 0):
          print("Added " + str(num_posts) + " posts")

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
       
        mentioned_modified_coins = extract_mentioned_coins(
            modified_coin_names, content, subject, args.extra_strings,
            modified_search_subject, modified_search_content,
            modified_both_name_and_symbol)
        mentioned_unmodified_coins = extract_mentioned_coins(
            unmodified_coin_names, content, subject, args.extra_strings,
            unmodified_search_subject, unmodified_search_content,
            unmodified_both_name_and_symbol)

        # Join all mentioned coins with |, a separator different from csv separator
        mentioned_modified_coins_str = "|".join(mentioned_modified_coins)
        mentioned_unmodified_coins_str = "|".join(mentioned_unmodified_coins)

        # Generate output row to output file
        output_row = [forum_id, subject_id, post_id, forum_page, subject_page,
                      num_replies, num_views, url, started_by, user, user_level,
                      user_activity, date, time,
                      mentioned_modified_coins_str, mentioned_unmodified_coins_str]
        post_timestamp = " ".join([date, time])
        posts_keyed_by_timestamp[post_timestamp].append(output_row)
      infile.close()

    print("Sorting the posts by timestamp...")
    posts_keyed_by_timestamp_sorted = collections.OrderedDict(
        sorted(posts_keyed_by_timestamp.items()))
    print("Finished sorting the posts by timestamp")
    
    # prepare output file and write header to output
    output_dir = os.path.dirname(args.output)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    output_file = open(args.output, 'w')
    csvwriter = csv.writer(output_file, delimiter=',')
    csvwriter.writerow(header)
    for timestamp_rows in posts_keyed_by_timestamp_sorted.itervalues():
        for timestamp_row in timestamp_rows:
            csvwriter.writerow(timestamp_row)

