#!/usr/bin/python

import argparse
import collections
import csv
import os
import sys
import datetime
import utils

parser = argparse.ArgumentParser(
    description='This script extracts multiple sets of users per coin. '
                'The following is a description of these  different sets:'  
                '1-The users who have mentioned the unmodified coin for the first time '
                'in any post any date.   '
                '2-The users who have mentioned both the unmodified coin for the first '
                'time in a post that starts a new thread any date.   '
                'Note that this script does not decide whether a modifed or unmodified '
                'coin is mentioned in a post. The mentioned coins per post are provided '
                'as input. In other words, the input is free to decide on whatever '
                'mention scheme to use.')
parser.add_argument("forum_input",
                    help="The location of CSV file containing posts from all forums "
                    "sorted by date and time. The last two columns of file should "
                    "contain the list of modified and unmodified coins mentions in the "
                    "post.")
parser.add_argument("output_dir",
                    help="The directory where the users lists will be written to. These "
                    "will be multiple csvs. For example, a CSV file will also be written "
                    "to this directory mapping each coin name to the list of its most "
                    "active users (those who had mentioned the coin the most at time of "
                    "the network). Another CSV file containing the first introducers "
                    "of the coins will be also written to this folder.");
parser.add_argument("unmodified_coins_earliest_trade_dates",
                    help="A CSV file containing the earliest possible introduction date "
                    "for each unmodified coin. The first line is the header and each "
                    "following line looks like 'coin-name,YYYY/MM/DD' where the date is "
                    "the earliest possible introduction date for that coin. Depending on "
                    "the output file, mentions of a coin in a thread at a time older "
                    "than its earliest possible date is ignored")
parser.add_argument("-hd", "--history_days", type=int, default = -1,
                    help="This value determines the number of days of forum interactions "
                    "prior to introduction of the coin that are used for constructing "
                    "the network. For example, value of 7 means that posts older than 7 "
                    "days are not accounted in construction of each coin interaction "
                    "network. Negative values indicates an unlimited number of days: "
                    "All posts before earliest date are counted, no matter how old. "
                    "Default is a negative value.")
args = parser.parse_args()

class PostsTracker:
  def __init__(self):
    # Read earliest possible introduction dates. First one is mapping from coin name to
    # earliest trade date and second one is reverse: mapping from date to list of
    # coins whose earliest trade is the key date.
    self.earliest_trade_date_by_unmodified_coin = dict()
    unmodified_coins_by_earliest_trade_date = collections.defaultdict(set)   # Dummy
    utils.read_earliest_trade_dates(args.unmodified_coins_earliest_trade_dates,
                              self.earliest_trade_date_by_unmodified_coin,
                              unmodified_coins_by_earliest_trade_date)

    # mapping from coin symbol to its name to be included in outputs
    self.name_by_unmodified_coin = dict()
    coin_by_unmodified_name = dict()
    utils.read_coin_name_symbols(args.unmodified_coins_earliest_trade_dates,
                                 self.name_by_unmodified_coin,
                                 coin_by_unmodified_name)
   
    # mapping from coin to earliest mention in the forum or earliest mention in the first
    # post of a new thread.
    self.first_mention_date_by_unmodified_coin = dict()
    self.first_thread_post_mention_date_by_unmodified_coin = dict()

    # Used for tracking users in 1st list: 
    # The users who have mentioned the unmodified coin name AND symbol for
    # the first time in any post any date
    # A mapping from coin name to the first user that mentions that coin. This could have
    # been a simple dict, but for consistency, the structure of this is similar to
    # coin_mention maps. The number of mentions for any user will always be one, and we
    # will only track of one user per coin.
    # This could be full of false positives, and that's why we look at number of mentions.
    # It could still be useful if coin mentions are assigned when both name and symbol are
    # present in the text.
    self.unmodified_first_mention = collections.defaultdict(
        lambda: collections.defaultdict(int)) 
    # Keeps track of url and date of the first mention of each coin by users in the second
    # list. A mapping from coin name to the URL and date of the first mention.
    self.unmodified_first_mention_date_url = collections.defaultdict(
        lambda: collections.defaultdict(list))

    
    # Used for tracking users in 2nd list: 
    # The users who have mentioned both the unmodified coin name AND symbol 
    # for the first time in a post that starts a new thread any date.
    # This could have been a simple dict, but for consistency we employed the same
    # structure and coin_mention maps.
    self.unmodified_first_thread_post_mention = collections.defaultdict(
        lambda: collections.defaultdict(int)) 
    # Keeps track of url and date of the first mention of each coin in first post of a
    # thread by users in the fourth list.
    self.unmodified_first_thread_post_mention_date_url = collections.defaultdict(
        lambda: collections.defaultdict(list))

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
 
  
  def add_unmodified_coin_first_mention(self, unmodified_coin, user, date_time, url):
    # we don't care if the first mention is after earliest date. we update first mention
    # if mentioned coin is observed for first time, no matter the date
    if unmodified_coin in self.first_mention_date_by_unmodified_coin:
      return
  
    # the following code should happen only once, so we overwrite.
    self.unmodified_first_mention[unmodified_coin][user] = 1
    self.unmodified_first_mention_date_url[unmodified_coin][user] = [
        (url, date_time)]
    self.first_mention_date_by_unmodified_coin[unmodified_coin] = date_time.date()
  
  
  def add_unmodified_coin_first_thread_post_mention(self,
                                                    unmodified_coin,
                                                    user, date_time,
                                                    url):
    # we don't care if the first mention is after earliest date. we update first mention
    # if mentioned coin is observed for first time, no matter the date
    if unmodified_coin in self.first_thread_post_mention_date_by_unmodified_coin:
      return

    # the following code should happen only once, so we overwrite.
    self.unmodified_first_thread_post_mention[unmodified_coin][user] = 1
    self.unmodified_first_thread_post_mention_date_url[unmodified_coin][user] = [
        (url, date_time)]
    self.first_thread_post_mention_date_by_unmodified_coin[unmodified_coin] = date_time.date()


  # just like modified coin mentions, but keeps track of both modified coin name and
  # symbol mentions
  def add_unmodified_coin_mention(self, unmodified_coin, user, date_time, new_subject, url):
    # first take care of first mentions if any
    self.add_unmodified_coin_first_mention(unmodified_coin, user, date_time, url)
    if new_subject:
      self.add_unmodified_coin_first_thread_post_mention(unmodified_coin, user, date_time,
                                                         url)
    
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



  def write_unmodified_coin_first_mentioners(self):
    first_introducers_output_filename = os.path.join(
        args.output_dir, "unmodified_coin_first_introducers.csv")
    utils.write_coin_users(first_introducers_output_filename,
                           self.name_by_unmodified_coin,
                           self.unmodified_first_mention,
                           self.num_posts_per_user,
                           self.num_subjects_per_user,
                           self.first_post_per_user,
                           self.earliest_trade_date_by_unmodified_coin,
                           self.first_mention_date_by_unmodified_coin,
                           self.earliest_trade_date_by_unmodified_coin,
                           1)
    urls_output_filename = os.path.join(
        args.output_dir, "unmodified_coin_first_introducer_urls.csv")
    utils.write_coin_user_urls(urls_output_filename,
                               self.name_by_unmodified_coin,
                               self.unmodified_first_mention_date_url,
                               self.earliest_trade_date_by_unmodified_coin,
                               self.first_mention_date_by_unmodified_coin,
                               1, 1)


  def write_unmodified_coin_first_thread_post_mentioners(self):
    first_thread_post_introducers_output_filename = os.path.join(
        args.output_dir, "unmodified_coin_first_thread_post_introducers.csv")
    utils.write_coin_users(first_thread_post_introducers_output_filename,
                           self.name_by_unmodified_coin,
                           self.unmodified_first_thread_post_mention,
                           self.num_posts_per_user,
                           self.num_subjects_per_user,
                           self.first_post_per_user,
                           self.earliest_trade_date_by_unmodified_coin,
                           self.first_thread_post_mention_date_by_unmodified_coin,
                           self.earliest_trade_date_by_unmodified_coin,
                           1)
    urls_output_filename = os.path.join(
        args.output_dir, "unmodified_coin_first_thread_post_introducer_urls.csv")
    utils.write_coin_user_urls(urls_output_filename,
                               self.name_by_unmodified_coin,
                               self.unmodified_first_thread_post_mention_date_url,
                               self.earliest_trade_date_by_unmodified_coin,
                               self.first_thread_post_mention_date_by_unmodified_coin,
                               1, 1)


if __name__ == '__main__':

  if os.path.isfile(args.output_dir):
    sys.exit("Output dir " + args.output_dir + " is an existing file.")
  if not os.path.isdir(args.output_dir):
    os.makedirs(args.output_dir)

  posts_tracker = PostsTracker()
  with open(args.forum_input, mode='r') as infile:
    reader = csv.reader(infile)
    next(reader, None)  # skip the headers

    # a set that keeps track of subject ids seen so far. Used to distinguish first post in
    # a thread. New subjects are not in the set
    full_subject_ids = set()

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

      # update first introducer of coin
      for unmodified_coin in unmodified_coins:
        posts_tracker.add_unmodified_coin_mention(unmodified_coin,
                                                  user,
                                                  date_time,
                                                  new_subject,
                                                  url)
  
  
  # After we have processed all the posts, write the user sets.  
  posts_tracker.write_unmodified_coin_first_mentioners()
  posts_tracker.write_unmodified_coin_first_thread_post_mentioners()
