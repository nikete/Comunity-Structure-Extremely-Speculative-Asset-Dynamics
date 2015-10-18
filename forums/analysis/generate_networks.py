#!/usr/bin/python
#
# This script creates the directed or undirected discussion networks on bitcoin and
# altcoin forums.  It assumes the input file contains the posts in individual subjects of
# the forum, sorted by time. It is absolutely important for the posts in the input file to
# be sorted by time.  The interaction graphs will be written to output_dir in pickle
# format, one file per coin.  To read the graphs back, use:
#    g=igraph.Graph.Read_Pickle(coin_name_file)  
# where coin_name_file should be replaced with the path to the file containing the graph:
#    "./output_dir/BTC"

# input file should contain the following columns
# "forum_id", "subject_id", "post_id", "forum_page", "subject_page", "num_replies",
# "num_views", "url", "started_by", "user", "user_level", "user_activity", "date",
# "time", "mentioned_modified_coins", "mentioned_unmodified_coins"
#
# In undirected network, the edge weight between two nodes can be computed in two ways:
# 1- Each time user1 and user2 co-appear in a thread, 1 will be added to their edge weight
# 2- Each time user1 and user2 co-appear in a thread, 1/num_posts_in_thread_so_far will be
#    added to their edge weight (enable by --weigh_thread)
# Each of the above methods can be modified such that the edge weights decay by a factor
# on a daily basis.
#
# In directed network, there is an edge from any user who posts on a thread to the
# originator of the thread. The weight of the directed edges can be computed in
# two ways:
# 1- Regular: each post from user a on a thread started by user b adds 1 to the
# weight of the edge from user a to user b.
# 2- Weighted: each post from user a on a thread started by user b adds
# 1/num_posts_in_thread_so_far to the weight of the edge from user a to user b.
# Each of the possible graph construction schemes above can become a decaying
# graph, where the weights on edges decay on a daily basis by a decay factor
# provided as an input.

import argparse
import itertools
import os
import csv
import sys
import collections
import igraph
import datetime
import operator
import utils

parser = argparse.ArgumentParser(
    description='This script generates either the directed satoshi network or the '
    'undirected network per date.  We wiill take snapshot of the network whenever we '
    'observe a new date in the posts. Edge construction is different in directed and '
    'undirected networks. Read file level comments for details.')
parser.add_argument("forum_input",
                    help="The location of CSV file containing posts from all forums "
                    "sorted by date and time. The last column of file should contain the "
                    "list of coins mentions in the post.")
parser.add_argument("output_dir",
                    help="The directory where the interaction graph snapshots will be "
                    "written to. There will be a file per date with posts in this "
                    "directory, each containing the serialized graph. The filenames will "
                    "be the date of the network.")
parser.add_argument("-w", "--weigh_thread",
                    action="store_true", default=False,
                    help="Weigh/Scale down co-appearance in a thread by number of posts "
                    "in the thread")
parser.add_argument("-d", "--decay_factor", type=float, default = -1.0,
                    help="This value determines how the edge weights should decay on a "
                    "daily basis If positive, all edge weights will be multiplied by "
                    "this factor every new day. Possible values are between 0 and 1. "
                    "Negative values disable decay")
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
parser.add_argument("-v", "--verbose", help="Print verbose output",
                    action="store_true", default=False)
args = parser.parse_args()


if __name__ == '__main__':
  (output_dir, decay_factor) = utils.check_input_params(args)

  # Keeps track of number of posts on the forum subject so far. So that when a
  # new user joins the subject, we can assign the right edge weights it forms
  # with other contributors in the subject.
  # It's a mapping from full subject id to number of posts, where full subject is is 
  # "forum_id,subject_id"
  subject_activity = collections.defaultdict(int)
  
  # dict from (vertex1, vertex2) to edge weight. It is updated as we read more
  # and more posts by either adding new edges or incrementing weights. Note
  # that the key denotes a directed edge: (v1, v2) is different from (v2, v1)
  edge_weights = collections.defaultdict(float)
  vertex_names = set()
 
  # a dictionary from full subject id ("forum_id,subject_id") to list of users who
  # contributed in it. We keep track of the contributing users because we don't want to
  # add an edge from user a to user b, if we have already seen user a contribute in the
  # thread and have already added an edge between a and b or updated the weight for the
  # edge.
  subject_contributors = collections.defaultdict(set)

  with open(args.forum_input, mode='r') as infile:
    reader = csv.reader(infile)
    next(reader, None)  # skip the headers

    # Can't set prev_date to small date, because we should not decay the edges in the
    # first_date
    prev_date = None

    for input_row in reader:
      # extract relevant data from input_row. There are a lot more data that are available
      # in the row, but extract_fields does not return them. add them back on demand.
      (full_subject_id, started_by, user, date_time,
       mentioned_modified_coins, mentioned_unmodified_coins,
       url) = utils.extract_fields_from_row(input_row)
      # Set the prev_date to the first day in the data.
      if prev_date is None:
        prev_date = datetime.date(date_time.year, date_time.month, date_time.day)

      # only if decay factor is non negative, decay all the edge weights
      new_date = date_time.date() != prev_date
      # Taking snapshots per day or mentioned coin? We will take a snapshot as
      # soon as we observe a new date. This should also happen before we decay the edges
      # for the new date, because the snapshot corresponds to the end of the previous date
      # where the edges did had not decayed yet.
      # Snapshots are taken at the END OF PREVIOUS day. So date 2014-02-02 network
      # represents whatever discussion up to end of 2014-02-01.  Same is true for a coin
      # whose earliest trade in on 2014-02-02, its network only contains interactions up
      # to end of 2014-02-01 (beginning of 2014-02-02).
      if new_date:
        utils.write_network(output_dir, str(date_time.date()), vertex_names,
                            edge_weights, args.directed_network, args.csv_output)
  
        # Now that we took a snapshot of the networks from previous date, we can decay
        # edges.
        if decay_factor > 0:
          utils.decay_edges(edge_weights, decay_factor)
      
      # update the date now that we have checked for new date.
      prev_date = datetime.date(date_time.year, date_time.month, date_time.day)
      
      # Update total activity on subject so far so that we can assign the right edge
      # weight for new contributors in the subject.
      new_subject = full_subject_id not in subject_activity
      subject_activity[full_subject_id] += 1
      
      # add user to graph if not added yet.
      vertex_names.add(user)
      
      utils.update_edge_weights(user, started_by, args.directed_network,
                                args.weigh_thread,
                                subject_activity[full_subject_id],
                                subject_contributors[full_subject_id],
                                edge_weights)
      # add user to the post contributors
      (subject_contributors[full_subject_id]).add(user)
