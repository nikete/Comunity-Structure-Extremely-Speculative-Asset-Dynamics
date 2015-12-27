import argparse
import itertools
import operator
import os
import csv
import sys
import collections
import igraph
import math
import datetime

# Makes sure input arguments to the program are OK, and if so parses and returns them
def check_input_params(args):
  if not os.path.isfile(args.forum_input):
    sys.exit('Could not find forum input file %s.' % args.forum_input)
  
  # prepare output directory
  output_dir = os.path.join(args.output_dir, "")
  if not os.path.exists(output_dir):
    try:
      os.makedirs(output_dir)
    except OSError as exception:
      sys.exit('Could not create output directory %s' % output_dir)

  decay_factor = args.decay_factor if hasattr(args, 'decay_factor') else None
  if decay_factor > 1.0:
    sys.exit('Invalid decay factor greater than one %d' % decay_factor)
  return (output_dir, decay_factor)

# Helper method for creating a list vertices name compatible with igraph graph
# construction
def create_vertex_list(vertex_names):
  vertices_list = list()
  for vertex_name in vertex_names:
    vertices_list.append({"name": vertex_name})
  return vertices_list

# Helper method for creating a list edges compatible with igraph graph construction
def create_edge_list(edge_weights):
  # First element of the tuple is the "From" node and second element is the "To" node.
  edges_list = list()
  for edge, edge_weight in edge_weights.iteritems():
    edges_list.append({"source": edge[0], "target": edge[1], "weight": edge_weight})
  return edges_list

# Creates and writes a directed or undirected graph based on the vertices and their edge
# weights.  directed should be a boolean indication whether this is a directed network or
# not.
def write_network(output_dir, network_name, vertex_names, edge_weights, directed,
                  csv_output):
  network_filename = os.path.join(output_dir, network_name)
  # Create the graph based on edge and vertex list so far. Do not add vertices
  # iteratively! it will take a long time.
  vertices_list = create_vertex_list(vertex_names)
  edges_list = create_edge_list(edge_weights)
  if csv_output:
    with open(network_filename, 'w') as csvfile:
      edges_writer = csv.writer(csvfile, delimiter = ',')
      edges_writer.writerow(['source', 'target', 'weight'])
      for edge in edges_list: 
        edges_writer.writerow([edge['source'], edge['target'], edge['weight']])
  else:
    interactions = igraph.Graph.DictList(vertices_list, edges_list, directed,
                                         "name", ("source", "target"), False)
    interactions.write_pickle(network_filename)
  
def write_coin_users(users_output_filename,
                     name_by_coin,
                     coin_mentions_per_user,
                     num_posts_per_user,
                     num_subjects_per_user,
                     first_post_per_user,
                     earliest_trade_date_by_coin,
                     earliest_mention_date_by_coin,
                     network_date_by_coin,
                     num_users):
  """ Write the coin most active users (top mentioners) along with some activity stats
  to an output file.

  name_by_coin: mapping from coin symbol to its name
  coin_mentions_per_user: a mapping from coin name to a another mapping from user to
  number of times the user mentioned the coin *before the network date*.
  num_posts_per_user: mapping from user to another mapping from date to number of posts
  made by user up to that date
  num_subjects_per_user: mapping from user to another mapping from date to number of
  subjects initiated by the user up to that date
  first_post_per_user: mapping from user to date of her first post on the forum
  earliest_trade_date_by_coin: a mapping from coin name to the earliest date coin is
  traded for.
  earliest_mention_date_by_coin: a mapping from coin name to the earliest date coin is
  mentioned in the forum by any of the active users.
  network_date_by_coin: a mapping from coin name to the date at which stats above are
                        computed. This could be simply the earliest trade date or date of
                        first mention.
  num_users: the number of most active users to write the file: this many active
  users with their number of mentions will be written to output.
  """
  csvwriter = csv.writer(open(users_output_filename, 'w'), delimiter=',')
  header = ["symbol", "name", "earliest_trade_date", "earliest_mention_date",
            "network_date"]
  for i in range(1, num_users+1):
    header.append("user" + str(i))
    header.append("user" + str(i) + "_num_mentions")
    header.append("user" + str(i) + "_num_posts")
    header.append("user" + str(i) + "_num_subjects")
    header.append("user" + str(i) + "_days_since_first_post")
  csvwriter.writerow(header)

  for coin, mentions_per_user in coin_mentions_per_user.iteritems():
    # don't output if coin has no earliest trade or mention date
    if (coin not in earliest_trade_date_by_coin or
        coin not in earliest_mention_date_by_coin or
        coin not in name_by_coin or
        coin not in network_date_by_coin):
      continue
    
    name = name_by_coin[coin]
    coin_earliest_trade_date = earliest_trade_date_by_coin[coin]
    coin_earliest_mention_date = earliest_mention_date_by_coin[coin]
    coin_network_date = network_date_by_coin[coin]

    # sort the users by number of mentions
    mentions_per_user_sorted = sorted(mentions_per_user.items(),
                                      key=operator.itemgetter(1),
                                      reverse=True)
    
    coin_output_row = [coin, name, coin_earliest_trade_date, coin_earliest_mention_date,
                       coin_network_date]
    # iterate over all acitve users for this coin. The number of active users could be
    # less than the max above.
    for i in range(0,num_users):
      if i < len(mentions_per_user_sorted):
        user = mentions_per_user_sorted[i][0]
        user_num_mentions = mentions_per_user_sorted[i][1]
        # get number of posts/subjects made in all dates prior to network date
        num_posts = [0]
        num_posts.extend(v for k,v in num_posts_per_user[user].iteritems()
                         if k < coin_network_date)
        user_num_posts = max(num_posts)
        num_subjects = [0]
        num_subjects.extend(v for k,v in num_subjects_per_user[user].iteritems()
                            if k < coin_network_date)
        user_num_subjects = max(num_subjects)
        user_days_since_first_post = (coin_network_date - first_post_per_user[user]).days
      else:
        user = ""
        user_num_mentions = ""
        user_num_posts = ""
        user_num_subjects = ""
        user_days_since_first_post = ""
      coin_output_row.append(user)
      coin_output_row.append(user_num_mentions)
      coin_output_row.append(user_num_posts)
      coin_output_row.append(user_num_subjects)
      coin_output_row.append(user_days_since_first_post)
    
    csvwriter.writerow(coin_output_row)

def write_coin_user_urls(urls_output_filename,
                         name_by_coin,
                         coin_urls_per_user,
                         earliest_trade_date_by_coin,
                         earliest_mention_date_by_coin,
                         num_users, num_urls):
  """ Writes the url and dates where active/first introducer users mentioned the coin.
  
  name_by_coin: mapping from coin symbol to its name
  num_users: the number of most active/first introducer users to write to the file.
  num_urls: the number of urls/dates per user.
  """

  if not num_urls > 0:
    return

  csvwriter = csv.writer(open(urls_output_filename, 'w'), delimiter=',')
  header = ["symbol", "name", "earliest_trade_date", "earliest_mention_date"]
  for i in range(1, num_users+1):
    header.append("user" + str(i))
    for j in range(1, num_urls+1):
      header.append("user" + str(i) + "_url" + str(j))
      header.append("user" + str(i) + "_date" + str(j))
  csvwriter.writerow(header)

  for coin, urls_per_user in coin_urls_per_user.iteritems():
    # don't output if coin has no earliest trade or mention date
    # don't output if coin has no earliest trade or mention date
    if (coin not in earliest_trade_date_by_coin or
        coin not in earliest_mention_date_by_coin or
        coin not in name_by_coin):
      continue

    name = name_by_coin[coin]
    coin_earliest_trade_date = earliest_trade_date_by_coin[coin]
    coin_earliest_mention_date = earliest_mention_date_by_coin[coin]

    if not len(urls_per_user):
      continue
    
    # sort the users by number of urls
    urls_per_user_sorted = sorted(urls_per_user.items(),
                                  key=lambda k: len(k[1]),
                                  reverse=True)
    
    coin_output_row = [coin, name, coin_earliest_trade_date, coin_earliest_mention_date]
    for i in range(0, num_users):
      if i < len(urls_per_user_sorted):
        user = urls_per_user_sorted[i][0]
        user_date_urls = urls_per_user_sorted[i][1]
      else:
        user = ""
        user_date_urls = []

      coin_output_row.append(user)
      # elements of the list are tuples of (url, date)
      for j in range(0, num_urls):
        url = user_date_urls[j][0] if j < len(user_date_urls) else ""
        date = user_date_urls[j][1].date() if j < len(user_date_urls) else ""
        coin_output_row.append(url)
        coin_output_row.append(date)
    
    csvwriter.writerow(coin_output_row)


# decays the weights on all edges by decay_factor. edge_weights must be a mapping from
# (source,target) edge key to its weight.
def decay_edges(edge_weights, decay_factor):
  edge_weights.update({k: v*decay_factor for k, v in edge_weights.items()})
    

# reads a csv file with lines like (coin-name,earliest-introduction-date) and updates the
# corresponding dictionaries
def read_earliest_trade_dates(introduction_dates_file,
                              earliest_trade_date_by_coin,
                              coins_by_earliest_trade_date):
  with open(introduction_dates_file, 'r') as infile:
    reader = csv.reader(infile)
    next(reader, None)  # skip the headers
    for row in reader:
      earliest_trade_date = datetime.datetime.strptime(row[2], '%Y-%m-%d').date()
      earliest_trade_date_by_coin[row[1]] = earliest_trade_date
      coins_by_earliest_trade_date[earliest_trade_date].add(row[1])

def read_coin_name_symbols(input_file,
                           name_by_coin,
                           coin_by_name):
  with open(input_file, 'r') as infile:
    reader = csv.reader(infile)
    next(reader, None)  # skip the headers
    for row in reader:
      name = row[0]
      coin = row[1]
      name_by_coin[coin] = name
      coin_by_name[name] = coin


# Takes a row from the input file containing posts, parses it and returns a tuple
# containing relevent fields of the row. Many of the fields are not returned, add them
# back on demand.
# full_subject_id is "concat(forum_id,subject_id)"
def extract_fields_from_row(input_row):
  # raw fields
  forum_id = input_row[0]
  subject_id = input_row[1]
  post_id = input_row[2]
  forum_page = input_row[3]
  subject_page = input_row[4]
  num_replies = input_row[5]
  num_views = input_row[6]
  url = input_row[7]
  started_by = input_row[8]
  user = input_row[9]
  user_level = input_row[10]
  user_activity = input_row[11]
  date = input_row[12]
  time = input_row[13]
  mentioned_modified_coins = [x for x in input_row[14].split('|') if x]
  mentioned_unmodified_coins = [x for x in input_row[15].split('|') if x]
 
  # composite fields
  date_time = datetime.datetime.strptime(date + ' ' + time, '%Y-%m-%d %H:%M:%S')
  full_subject_id = ",".join([forum_id, subject_id])
  return (full_subject_id, started_by, user, date_time, mentioned_modified_coins,
          mentioned_unmodified_coins, url)


# creates a new edge or updates the weight of the edge in edge_weights.
# edge_weights is a dict of edges keyed by (source, target). It also updates the set of
# subject_contributors by adding the user to it.
# undirected_network is a bool which indicates whether we are creating an undirected edge
# or not.
# subject_activity is the level activity in the thread where this edge/post comes from.
# subject_contributors is the set of contributors in the thread where this edge/post
# comes from.
#
# Directed edges: Increase the weight or add an edge between this contributor and the user
# who originated the thread. This will be done on a directed edge from the contributor to
# the starter of the thread. The idea is that a directed edge to originator grants him
# influence and power.  Do this only if this contributor is new in the subject. Weights
# are updated according to thread activity.
#
# Indirected edges: Increase the weight between this contributor and previous
# contributors, only if this contributor is new in the subject. Weights are updated
# according to co-appearance in a thread.
def update_edge_weights(user, started_by, directed_network, weigh_thread,
                        subject_activity,
                        subject_contributors,
                        edge_weights):
  # If already in subject_contributors bail out.
  if user in subject_contributors:
    return

  if directed_network:
    # don't add an edge from user to herself.
    if user != started_by:
      # First element in the tuple is the from node of the edge and second
      # element is the to node of the edge.
      edge = (user, started_by)
      edge_weight = 1.0
      # weigh the edge by the total activity up to when this user made the post
      if weigh_thread:
        edge_weight /= subject_activity
      edge_weights[edge] += edge_weight
  else:
    for contributor in subject_contributors:
      # Need to always sort source and target. stupid igraph does not understand
      # that: (source: "A", target: "B") is the same edge as (source: "B", target:
      # "A") when the graph is undirected. So we enforce a specific order between
      # source and target.  First element in the tuple will become the source,
      # second will be target.
      edge = tuple(sorted((user, contributor)))
      edge_weight = 1.0
      if weigh_thread:
        edge_weight /= subject_activity
      edge_weights[edge] += edge_weight


def round_to_sigfigs(value, num_sigfigs):
  """ Returns the rounded input (integer or float) to requested number of significant
  digits.

  num_sigfigs: number of significant digits.
  """

  # don't take log of zero or operate on nan
  if math.isnan(value) or value == 0:
    return value
  # location of first significant digit
  first_sigfig = int(math.floor(math.log10(abs(value))))
  return round(value, -(first_sigfig - num_sigfigs + 1))
