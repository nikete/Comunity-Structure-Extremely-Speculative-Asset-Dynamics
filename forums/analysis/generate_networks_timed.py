#!/usr/bin/python
# 
# This file is very similar to generate_networks.py and generates directed or undirected
# interaction networks either by date or the earliest time a coin is traded. Its only
# difference with generate_networks.py is that it takes an extra argument which determines
# how far in time to go back for creating the network interactions/edges. The idea is that
# interactions that happened a year ago, should not be important in determing the
# structure of the graph. If the extra argument receives a value of 7, only the
# interactions in the past 7 days prior to first mention of the coin are used in
# constructing the interaction graph.  Since we are only considering recent history, there
# will be no decay factor in this file (compared to untimed version which support edge
# weight decay).
#
# Similar to generate_networks.py, it requires an extra input which detemines the earliest
# time a coin is traded, if coin networks, and not per-day networks, are requested.
# Similarly again, it outputs a separate file "coin_active_users.csv" will be written to
# output_dir and will contain the list of users who have mentioned each coin the most at
# the time the coin network snapshot was taken. In contrast to generate_networks.py, all
# mentions of the coin up to snapshot time are considered but only any mention within the
# past 7 days (if 7 is the duration of our interest).
#
# Read generate_networks.py for more info, input file format and difference between
# directed and undirected networks.

import argparse
import itertools
import copy
import os
import csv
import sys
import collections
import igraph
import datetime
import utils

parser = argparse.ArgumentParser(
    description='This script generates either the directed satoshi network or the '
    'undirected network at the earliest time the coin was mentioned. You can also '
    'generate network per date, instead of per coin. In either case, only the posts '
    'within the past x days will be considered, where x is specified by the user. '
    'Edge construction is different in directed and undirected networks. Read file level '
    'comments for details.')
parser.add_argument("forum_input",
                    help="The location of CSV file containing posts from all forums "
                    "sorted by date and time. The last column of file should contain the "
                    "list of coins mentions in the post.")
parser.add_argument("output_dir",
                    help="The directory where the interaction graph snapshots will be "
                    "written to. There will be a file per mentioned coin in this "
                    "directory, each containing the serialized graph. The filenames will "
                    "be the name of the coin mentioned.")
parser.add_argument("-hd", "--history_days", type=int, default = 30,
                    help="This value determines the number of days of forum interactions "
                    "prior to introduction of the coin that are used for constructing "
                    "the network. For example, value of 7 means that posts older than 7 "
                    "days are not accounted in construction of each coin interaction "
                    "network.")
parser.add_argument("-w", "--weigh_thread",
                    action="store_true", default=False,
                    help="Weigh/Scale down co-appearance in a thread by number of posts "
                    "in the thread")
parser.add_argument("-dn", "--directed_network", dest='directed_network',
                    action="store_true", default=False,
                    help="Determines whether networks will be directed or undirected. "
                    "In directed networks, there is a directed edge from a subject "
                    "contributor to initiator of the thread. In undirected networks, "
                    "there is an edge between any two users who co-appear in a thread.")
parser.add_argument("-co", "--csv_output", dest="csv_output",
                    action="store_true", default=False,
                    help="Whether the generated networks should be written to output "
                    "location in csv format or not. The default is false, which stores "
                    "networks in pickle format.")
parser.add_argument("-v", "--verbose", action="store_true", default=False,
                    help="Print verbose output")
args = parser.parse_args()



class InteractionGraph:
  """
  Holds the data needed to construct the interaction network that goes back some days in
  time.
  """
  def __init__(self):
    # a dictionary from "forum_id,subject_id" to set of users who contributed in it.
    # Use this to update interactions graph. It only contains the users who have posted
    # something on the subject until the time of the latest post we are processing.
    # so if a user contributes to the subject after we take a snapshot, he/she will not
    # have an edge to originator of the subject (directed network) or previous
    # contributors (undirected network) because he/she was not added to this list yet.
    self.subject_contributors = collections.defaultdict(set)

    # Keeps track of number of posts on the forum subject so far. So that when a new user
    # joins the subject, we can assign the right edge weights it forms with other
    # contributors in the subject.
    self.subject_activity = collections.defaultdict(int)

    # dict from (vertex1, vertex2) to edge weight. It is updated as we read more and more
    # posts by either adding new edges or incrementing weights.
    self.edge_weights = collections.defaultdict(float)
    self.vertex_names = set()


  def add_post(self, full_subject_id, user, started_by):
    """
    Adds or updates the edge depending on the network type:
    1- In directed network, adds or update directed edge from user (poster in the thread)
    to started_by (originator of the thread). The idea is that a directed edge to
    originator grants him influence and power.
    2 - In undirected graph, adds or updates edge from user to all previous contributors
    of the thread.
    """
    # Update total activity on subject so far so that we can assign the right edge weight
    # for new contributors in the subject.
    self.subject_activity[full_subject_id] += 1
        
    # add user to graph if not added yet.
    self.vertex_names.add(user)

    # Increase the weight or add an edge between this contributor and the
    # user who originated the thread (directed) or other contributors (undirected).
    # from the contributor to the starter of the thread.
    # Update only if this contributor is new in the subject. Weights are updated
    # according to thread activity.
    utils.update_edge_weights(user, started_by, args.directed_network,
                              args.weigh_thread,
                              self.subject_activity[full_subject_id],
                              self.subject_contributors[full_subject_id],
                              self.edge_weights)
    
    # add user to the post contributors
    (self.subject_contributors[full_subject_id]).add(user)

  
  def write_graph(self, output_dir, coin):
    """
    Creates an igraph based on the data collected so far and writes to the output_dir.
    """
    utils.write_network(output_dir, coin, self.vertex_names,
                        self.edge_weights, args.directed_network, args.csv_output)
   
  
if __name__ == '__main__':
  (output_dir, decay_factor) = utils.check_input_params(args)

  # a mapping from coin names to list of users along with the number of times they
  # mentioned the coin in their posts. The counts will be tracked only up to the earliest
  # trade date of the coin.
  coin_mentions_per_user = collections.defaultdict(lambda: collections.defaultdict(int)) 
  
  # a FIFO queue of the interactions graphs along with the date they originate from. The
  # maximum number of graphs we hold, are the number of days in hisory we should go back
  # for constructing an interaction graph.  We will update all graphs in this list
  # whenever we encounter a new post. Each element in the list encapsulates the data
  # required to create the igraph network.
  # Each element will be a tuple of (date, InteractionGraph) where date corresponds to
  # starting date of the graph (i.e. all posts from the beginning of that date are
  # included in the graph).
  # We need to keep history_days + 1 networks in memory because we count history days from
  # the beginning of a day (or end of previous days). For example if hd=2, as soon as we
  # observe first post on date 4, we will have dates 2,3,4 in the queue. We need to keep 2
  # in the queue because activity starting from date 2 corresponds to network of date 4.
  networks_queue = collections.deque(maxlen = args.history_days + 1)

  with open(args.forum_input, mode='r') as infile:
    reader = csv.reader(infile)
    next(reader, None)  # skip the headers

    for input_row in reader:
      # extract relevant data from input_row. There are a lot more data that are available
      # in the row, but extract_fields does not return them. add them back on demand.
      (full_subject_id, started_by, user, date_time,
       mentioned_modified_coins, mentioned_unmodified_coins,
       url) = utils.extract_fields_from_row(input_row)
      
      # New date? if so add a new elements corresponding to this origin date to both
      # queues.
      post_date = date_time.date()
      new_date = post_date not in [network_tuple[0] for network_tuple in networks_queue]

      # If a new date, we need to remove networks that have become stale before we take a
      # snapshot of the network. Because stale networks are at the head of the deque and
      # they contains interactions that are older than history_days.
      if new_date:
        # First figure out if we should remove any graphs that are older than
        # history_days. The oldest networks are at the head of the queue.
        oldest_allowed_date = post_date - datetime.timedelta(days=args.history_days)
        while len(networks_queue) and networks_queue[0][0] < oldest_allowed_date:
          networks_queue.popleft()

        # Now any remaining graph is recent enough. Add this new graph.
        networks_queue.append((post_date, InteractionGraph()))

        # We will take a snapshot as soon as we observe a new date.  Snapshots are taken
        # at the END OF PREVIOUS day. So date 2014-02-02 network represents whatever
        # discussion up to end of 2014-02-01.  Same is true for a coin whose earliest
        # trade in on 2014-02-02, its network only contains interactions up to end of
        # 2014-02-01 (beginning of 2014-02-02). We have already removed stale networks, do
        # the first network in the queue is the oldest one, but not older than
        # history_days, so we will just snapshot the oldest graph present in the dequeu.
        # As an exmaple, if history_days=3, after observing the first post with
        # post_date=5, we will pop out networks with date=1. At this point, oldest network
        # will have date=2, which is exactly 3 days before the BEGINNING of this new
        # post_date (or END of last day).
        networks_queue[0][1].write_graph(output_dir, str(post_date))

      # Now that we have taken the snapshot (if had observed a new date), update all the
      # networks with the new post.
      for network_tuple in networks_queue:
        network_tuple[1].add_post(full_subject_id, user, started_by)
