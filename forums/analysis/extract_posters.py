#!/usr/bin/python

import argparse
import collections
import csv
import os
import sys
import datetime
import utils

parser = argparse.ArgumentParser(
    description='This script extracts coin introducers and their stats from '
                'a file that contains coin introduction URLs in the forum.')
parser.add_argument("forum_input",
                    help="The location of CSV file containing posts from all forums "
                    "sorted by date and time. The last two columns of file should "
                    "contain the list of modified and unmodified coins mentions in the "
                    "post.")
parser.add_argument("coins_earliest_trade_dates",
                    help="A CSV file containing the earliest possible introduction date "
                    "for each coin. The first line is the header and each "
                    "following line looks like 'coin-name,YYYY/MM/DD' where the date is "
                    "the earliest possible introduction date for that coin.")
parser.add_argument("coins_introduction_urls",
                   help="A CSV file mapping coin symbol to the URL of its announcement.")
parser.add_argument("output_dir",
                    help="The directory where the users lists will be written to.")
args = parser.parse_args()

class PostsTracker:
  def __init__(self):
    # Read earliest possible trade dates. First one is mapping from coin name to
    # earliest trade date and second one is reverse: mapping from date to list of
    # coins whose earliest trade is the key date.
    self.earliest_trade_date_by_coin = dict()
    coins_by_earliest_trade_date = collections.defaultdict(set)   # Dummy
    utils.read_earliest_trade_dates(args.coins_earliest_trade_dates,
                                    self.earliest_trade_date_by_coin,
                                    coins_by_earliest_trade_date)
    
    # mapping from coin symbol to its name to be included in outputs
    self.name_by_coin = dict()
    coin_by_name = dict()
    utils.read_coin_name_symbols(args.coins_earliest_trade_dates,
                                 self.name_by_coin,
                                 coin_by_name)
   
    # mapping from user to date of first post
    self.first_post_per_user = dict()

    # mapping from user to another mapping from date to number of posts made up to that
    # date
    self.num_posts_per_user = collections.defaultdict(
        lambda: collections.defaultdict(int))

    # mapping from user to another mapping from date to number of subjects initiated by
    # the user up to that date
    self.num_subjects_per_user = collections.defaultdict(
        lambda: collections.defaultdict(int))

    self.first_mention_date_by_coin = dict()
    # A mapping from coin name to the first user that mentions that coin. This could have
    # been a simple dict, but to be able to call utils method it's a map to another dict.
    # The number of mentions for any user will always be one, and we only track of one
    # user per coin.
    self.first_mention = collections.defaultdict(lambda: collections.defaultdict(int)) 
    # Keeps track of url and date of the first mention of each coin by users in the second
    # list. A mapping from coin name to the URL and date of the first mention.
    self.first_mention_date_url = collections.defaultdict(
        lambda: collections.defaultdict(list))
 

  def _update_user_activity(self, activity_per_user, user, date_time):
    post_date = date_time.date()
    # If new user, user_activity should be 1. If user is not new, but date is new,
    # user_activity should be one plus the maximum date smaller than date_time.
    if user not in activity_per_user:
      activity_per_user[user][post_date] = 1
    elif post_date not in activity_per_user[user]:
      # find largest date smaller than post_date. This assumes all previous dates have
      # been added before (input file is sorted by time)
      closest_date = max(k for k in activity_per_user[user] if k < post_date)
      activity_per_user[user][post_date] = activity_per_user[user][closest_date] + 1
    else:
      # both user and post_date have been added before.
      activity_per_user[user][post_date] += 1


  def add_user_post(self, user, date_time):
    """ Increments the number of posts by user upto date_time
    """
    self._update_user_activity(self.num_posts_per_user, user, date_time)
    if user not in self.first_post_per_user:
      self.first_post_per_user[user] = date_time.date()


  def add_user_subject(self, user, date_time):
    """ Increments the number of subjects by user upto date_time
    """
    self._update_user_activity(self.num_subjects_per_user, user, date_time)
  
  def add_coin_announcement(self, coin, user, date_time, new_subject, url):
    if coin in self.first_mention_date_by_coin:
      return

    # the following code should happen only once, so we overwrite.
    self.first_mention[coin][user] = 1
    self.first_mention_date_url[coin][user] = [(url, date_time)]
    self.first_mention_date_by_coin[coin] = date_time.date()

  
  def write_coin_announcements(self):
    coin_announcement_filename = os.path.join(
        args.output_dir, "coin_announcement.csv")
    utils.write_coin_users(coin_announcement_filename,
                           self.name_by_coin,
                           self.first_mention,
                           self.num_posts_per_user,
                           self.num_subjects_per_user,
                           self.first_post_per_user,
                           self.earliest_trade_date_by_coin,
                           self.first_mention_date_by_coin,
                           self.earliest_trade_date_by_coin,
                           1)
    urls_output_filename = os.path.join(
        args.output_dir, "announcement_urls.csv")
    utils.write_coin_user_urls(urls_output_filename,
                               self.name_by_coin,
                               self.first_mention_date_url,
                               self.earliest_trade_date_by_coin,
                               self.first_mention_date_by_coin,
                               1, 1)

if __name__ == '__main__':
  if os.path.isfile(args.output_dir):
    sys.exit("Output dir " + args.output_dir + " is an existing file.")
  if not os.path.isdir(args.output_dir):
    os.makedirs(args.output_dir)
  earliest_trade_date_by_coin = dict()
  name_by_coin = dict()
  with open(args.coins_earliest_trade_dates, mode='r') as infile:
    reader = csv.reader(infile)
    reader.next()
    for row in reader:
      name = row[0]
      coin = row[1].upper()
      earliest_trade_date = row[2]
      earliest_trade_date_by_coin[coin] = earliest_trade_date
      name_by_coin[coin] = name

  existing_coins_by_introduction_url = dict()
  existing_introduction_urls_by_coin = dict()
  missing_introduction_urls_by_coin = dict()
  invalid_introduction_urls_by_coin = dict()
  with open(args.coins_introduction_urls, mode='r') as infile:
    reader = csv.reader(infile)
    for row in reader:
      coin = row[0].upper()
      url = row[1]
      if 'bitcointalk' not in url:
        invalid_introduction_urls_by_coin[coin] = url
      elif coin not in earliest_trade_date_by_coin:
        missing_introduction_urls_by_coin[coin] = url
      else:
        existing_introduction_urls_by_coin[coin] = url
        existing_coins_by_introduction_url[url] = coin

 
  # write coin introduction urls that appear in our trade dates
  existing_coins_filename = os.path.join(args.output_dir, "existing.csv")
  csvwriter = csv.writer(open(existing_coins_filename, 'w'), delimiter=',')
  csvwriter.writerow(['symbol', 'introduction_url'])
  for coin, url in existing_introduction_urls_by_coin.iteritems():
    csvwriter.writerow([coin, url])
  
  # write coin introduction urls that do not appear in our trade dates
  missing_price_coins_filename = os.path.join(args.output_dir, "missing_price.csv")
  csvwriter = csv.writer(open(missing_price_coins_filename, 'w'), delimiter=',')
  csvwriter.writerow(['symbol', 'introduction_url'])
  for coin, url in missing_introduction_urls_by_coin.iteritems():
    csvwriter.writerow([coin, url])

  # write coins that do not appear in introduction list
  missing_url_coins_filename = os.path.join(args.output_dir, "missing_url.csv")
  csvwriter = csv.writer(open(missing_url_coins_filename, 'w'), delimiter=',')
  csvwriter.writerow(['symbol', 'name', 'earliest_trade_date'])
  for coin, earliest_trade_date in earliest_trade_date_by_coin.iteritems():
    if coin in existing_introduction_urls_by_coin:
      continue
    name = name_by_coin[coin]
    csvwriter.writerow([coin, name, earliest_trade_date])
  
  
  with open(args.forum_input, mode='r') as infile:
    reader = csv.reader(infile)
    next(reader, None)  # skip the headers

    # a set that keeps track of subject ids seen so far. Used to distinguish first post in
    # a thread. New subjects are not in the set
    full_subject_ids = set()

    posts_tracker = PostsTracker()
    for input_row in reader:
      # extract relevant data from input_row. There are a lot more data that are available
      # in the row, but extract_fields does not return them. add them back on demand.
      (full_subject_id, started_by, user, date_time,
       modified_coins, unmodified_coins,
       url) = utils.extract_fields_from_row(input_row)

      # if it's the first post in a thread, subject_id should be new.
      new_subject = full_subject_id not in full_subject_ids
      full_subject_ids.add(full_subject_id)

      posts_tracker.add_user_post(user, date_time)
      if new_subject:
        posts_tracker.add_user_subject(user, date_time)
      
      # check whether url exists in introduction urls and get the coin
      if url in existing_coins_by_introduction_url:
        coin = existing_coins_by_introduction_url[url]
        posts_tracker.add_coin_announcement(coin, user, date_time, new_subject, url)

  # After we have processed all the posts, write the user sets.  
  posts_tracker.write_coin_announcements()
