#!/usr/bin/python
# This scripts computes various metrics for directed and undirected discussion networks
# for each coin.  The most important metrics are distance to satoshi and personalized page
# rank of the coin active users in the case of directed graph. For the undirected graph,
# centrality measures of the coin active users will be computed. The metrics will be
# written to a csv, one line per coin discussion network.
# There is a flag to disable active users metrics in both directed and undirected cases,
# since they are very expensive. An extra flag determines whether the input graphs are
# directed or undirected.

import argparse
import os
import csv
import sys
import igraph
import collections
import multiprocessing
import utils

parser = argparse.ArgumentParser(
    description="This scripts takes a directory of interaction networks each written in "
                "Pickle format as input. Its output is a csv containing various network "
                "metrics characterizing general network structure and coin active users "
                "positional metrics in the graph, i.e. centrality, page rank, and "
                "satoshi distance. Each interaction network occupies one line in the "
                "output csv. The input directory must contain a file similar to "
                "coin_active_users.csv which contains the users who mention a coin the "
                "most in the forum.")
parser.add_argument("networks_input_dir",
                    help="The directory where the output of coin network generation "
                    "(generate_coin_network.py) is written to. Files in this directory "
                    "must be named by date corresponding to state of the discussion "
                    "network in that date.")
parser.add_argument("output_file",
                    help="The network measures per coin will be written to this file in "
                    "csv format. Each row will contain the coin network, user who "
                    "introduced the first, date of first introduction and all the "
                    "network measures")
parser.add_argument("-s", "--skip_general_metrics", dest="skip_general_metrics",
                    default = False, action = "store_true",
                    help="Whether we should compute general network metrics such as "
                    "density or number of vertices. These metrics are independent of any "
                    "coin and only depend on date. Default is false which means they "
                    "will be computed.")
parser.add_argument("-u", "--users_input_file", dest="users_input_file",
                    help="If provided, coin-specific measures for users in this "
                    "file (such as centrality, betweenness and coefficient) will be "
                    "computed. If provided, it should be the path to a file containing "
                    "information about a specific user or set of users per coin "
                    "(most active or introducer) for whom the centrality metrics will "
                    "be computed. If not provided, no user-specific metrics will be "
                    "computed, instead metrics will be computed by date date rather "
                    "than coin.")
parser.add_argument("-dn", "--directed_networks", dest="directed_networks",
                    default = False, action="store_true",
                    help="Whether the input graphs are undirected or directed discussion "
                    "networks. The metrics computed for directed and undirected graphs "
                    "and especially the active user metrics are different. Default is "
                    "false (undirected).")
parser.add_argument("-n", "--num_processes", dest="num_processes",
                    type = int, default = 1,
                    help="The number of processes to start in parallel. Each process "
                    "will compute metrics for one network at a time. The processes pass "
                    "the computed metrics to the main process which keeps track of all "
                    "network metrics.")
parser.add_argument("-v", "--verbose", help="Print verbose output",
                    action="store_true", default=False)
args = parser.parse_args()

# Number of significant figures to include in float metrics. We round decimal points,
# because igraph tends to return different values in high precisions decimal points in
# different invocations of the same method.
NUM_SIGFIGS = 7

# Increase the number of iterations it takes for ARPACK pagerank computation
igraph.arpack_options.maxiter=100000

# returns two dicts. one from coin to network snapshot date, other from coin to list of
# (user, num_coin_mentions_by_user) of active user for that coin
def read_coin_users(users_input_file):
  # a mapping from coin name list of (user, num_mentions).
  coin_users = collections.defaultdict(list)
  coin_network_dates = dict()
  coin_earliest_trade_dates = dict()
  coin_earliest_mention_dates = dict()
  max_num_coin_users = 0
  with open(users_input_file, 'r') as csvfile:
    csvreader = csv.reader(csvfile, delimiter = ',')
    next(csvreader, None)  # skip the headers
    for row in csvreader:
      coin = row[0]
      earliest_trade_date = row[1]
      earliest_mention_date = row[2]
      network_date = row[3]
      coin_earliest_trade_dates[coin] = earliest_trade_date
      coin_earliest_mention_dates[coin] = earliest_mention_date
      coin_network_dates[coin] = network_date
      # go through active users/num_mentions/num_posts/num_subjects
      num_coin_users = 0
      for i in range(4, len(row), 5):
        user = row[i]
        num_mentions = row[i+1]
        num_posts = row[i+2]
        num_subjects = row[i+3]
        days_since_first_post = row[i+4]

        # only add if we are not reading an empty field
        if user:
          num_coin_users += 1
          coin_users[coin].append((user, num_mentions,
                                   num_posts, num_subjects,
                                   days_since_first_post))
      max_num_coin_users = max(max_num_coin_users, num_coin_users)

  return (max_num_coin_users, coin_users,
          coin_earliest_trade_dates, coin_earliest_mention_date, coin_network_dates)


# Define weighted density as sum(edge weights)/(max number of possible edges) for directed
# graphs.  Since there can be two edges between two nodes (outgoing, incoming); thus we
# don't multiply sum(edge weights) by 2.
# For undirected graphs, weighted density is defined as
# 2*sum(edge weights)/(max number of possible edges)
# Returns zero if there are no edges.
def compute_network_weighted_density(network, directed_networks):
  if len(network.es) == 0:
    return 0

  num_vertices = len(network.vs)
  num_max_edges = num_vertices * (num_vertices - 1)
  sum_edge_weights = 0
  for edge_weight in network.es['weight']:
    sum_edge_weights += edge_weight

  if directed_networks:
    density = (sum_edge_weights / num_max_edges)
  else:
    density = (2.0 * sum_edge_weights / num_max_edges)
  return utils.round_to_sigfigs(density, NUM_SIGFIGS)


# Wrapper for computing weighted diameter of graph, since igraph can't handle a graph
# that has no edge, thus no 'weight' attribute. In such case, diameter is zero.
def compute_network_weighted_diameter(network, directed_networks):
  if len(network.es) == 0:
    return 0
  if directed_networks:
    return network.diameter(directed = True, unconn = True, weights = "weight")
  else:
    return network.diameter(directed = False, weights = "weight")


# Computes laplacian centrality, which can be considered a centrality measures based on
# weights of the graph. Only applicable to undrirected graph.
# TODO: make sure this actually makes sense and is correct!
def compute_laplacian_centrality(network, vertex):
  # find mapping from vertex to sum of edge weights
  vertex_weights = collections.defaultdict(float)
  for edge in network.es:
    source = edge["source"]
    target = edge["target"]
    weight = edge["weight"]
    vertex_weights[source] += weight
    vertex_weights[target] += weight
  neighbors = network.neighbors(vertex, mode="all")
  result = (vertex_weights[vertex]**2 + vertex_weights[vertex] +
            2 * sum(vertex_weights[i] for i in neighbors) )
  return utils.round_to_sigfigs(result, NUM_SIGFIGS)

# Wrapper for computing distance to satoshi in case satoshi no loner exists in the
# network.
def compute_user_satoshi_distance(network, user):
  if 'satoshi' not in network.vs["name"]:
    return float("inf")

  return network.shortest_paths(source='satoshi',
                                target=user,
                                weights=None,
                                mode='OUT')[0][0]

# Wrapper for computing personalized pagerank origination from Satoshi, since igraph can't
# handle a graph that has no edge, thus no 'weight' attribute. In such case, pagerank is 1
# since there is only user in the network.
# Personalized page rank is different from original page rank in that random walk is reset
# to a non-uniform distribution over vertices in each step with 1-damping-factor
# probability. In this case, since we want to measure the flow from Satoshi to coin
# active user, we set the reset_veritces to only contain Satoshi. In other words, random
# walk resets if they happen, will always start from Satoshi.
# Only applicable to directed networks.
def compute_user_satoshi_pagerank(network, user, weighted):
  if len(network.es) == 0:
    return 1
  if 'satoshi' not in network.vs["name"]:
    return 0

  # increase the pagerank computation max number of iterations. sometimes arpack does not
  # converge.
  options = igraph.ARPACKOptions()
  options.mxiter = 100000

  # Igraph 0.7 has a bad bug! It does not give pagerank of a specific user. It
  # only returns pagerank of first user in the graph, no matter what the
  # vertices argument is. So we get a list of all pageranks, then query in the
  # list with the index of node with name user
  user_index = network.vs.find(user).index

  if weighted:
    # if weights are requested, we should use the original weights rather than their inverse
    # (in contrast to closeness). In case of pagerank, large edge weights are good for the
    # incoming node. They give it more credit.
    weights = network.es['weight']
  else:
    weights = None

  # Vertices should be the active user whose page rank we want to compute. directed
  # should be true so that directed paths are considered. damping is the probability
  # that we reset the random walk on Satoshi at each step. reset_vertices should only
  # contain Satoshi, since we are interested in flow from Satoshi. weights should be
  # the 'weight' attribute so that weights are used in page rank computation.
  user_satoshi_pagerank = network.personalized_pagerank(
      directed=True, damping=0.85, reset_vertices='satoshi', weights=weights,
      implementation = "prpack", arpack_options = options)[user_index]
  if user_satoshi_pagerank > 1:
    sys.stderr.write('Error: Satoshi pagerank of user %s is greater than one: %f' %
                     (user, user_satoshi_pagerank))

  # Igraph returns tiny non-zero values for page ranks that should be really zero.
  # manually zero them out.
  if user_satoshi_pagerank < pow(10, -15):
    user_satoshi_pagerank = 0
  return utils.round_to_sigfigs(user_satoshi_pagerank, NUM_SIGFIGS)


# Wrapper for computing pagerank similar to above, but originatin randomly from any node
# in the graph.
def compute_user_pagerank(network, user, directed_networks, weighted):
  if len(network.es) == 0:
    return 1

  options = igraph.ARPACKOptions()
  options.mxiter = 100000

  # Igraph 0.7 has a bad bug! It does not give pagerank of a specific user. It
  # only returns pagerank of first user in the graph, no matter what the
  # vertices argument is. So we get a list of all pageranks, then query in the
  # list with the index of node with name user
  user_index = network.vs.find(user).index

  if weighted:
    # if weights are requested, we should use the original weights rather than their inverse
    # (in contrast to closeness). In case of pagerank, large edge weights are good for the
    # incoming node. They give it more credit.
    weights = network.es['weight']
  else:
    weights = None

  user_pagerank = network.pagerank(directed=directed_networks,
                                   damping=0.85, weights=weights,
                                   implementation = "prpack",
                                   arpack_options = options)[user_index]
  if user_pagerank > 1:
    sys.stderr.write('Error: Pagerank of user %s is greater than one: %f' %
                     (user, user_pagerank))

  # Igraph returns tiny non-zero values for page ranks that should be really zero.
  # manually zero them out.
  if user_pagerank < pow(10, -15):
    user_pagerank = 0
  return utils.round_to_sigfigs(user_pagerank, NUM_SIGFIGS)


def compute_user_betweenness_centrality(network, user, directed_networks, weighted):
  if len(network.es) == 0:
    return 1

  if weighted:
    # if weights are requested, we should use the inverse of weights, since higher weights
    # means more interactions between two users so the path length should be smaller
    weights = [1.0/w for w in network.es['weight']]
  else:
    weights = None

  user_betweenness = network.betweenness(vertices = user,
                                         directed = directed_networks,
                                         weights = weights,
                                         nobigint = False)
  return utils.round_to_sigfigs(user_betweenness, NUM_SIGFIGS)


# wrapper for computing density with rounding
def compute_network_unweighted_density(network):
  return utils.round_to_sigfigs(network.density(loops=True), NUM_SIGFIGS)


def compute_network_average_path_length(network, directed_networks):
  average_path_length = network.average_path_length(directed = directed_networks,
                                                    unconn = True)
  return utils.round_to_sigfigs(average_path_length, NUM_SIGFIGS)


# wrapper for computing average network clustering coefficient with rounding
def compute_network_clustering_coefficient(network):
  clustering_coefficient = network.transitivity_undirected(mode="zero")
  return utils.round_to_sigfigs(clustering_coefficient, NUM_SIGFIGS)


# wrapper for computing average network degree with rounding
def compute_network_average_degree(network):
  average_degree = network.degree_distribution().mean
  return utils.round_to_sigfigs(average_degree, NUM_SIGFIGS)


# wrapper for computing local clustering coefficient with rounding
def compute_user_clustering_coefficient(network, user):
  user_clustering_coefficient = network.transitivity_local_undirected(
      vertices = user, mode = "zero")
  return utils.round_to_sigfigs(user_clustering_coefficient, NUM_SIGFIGS)


# wrapper for computing closeness centrality with rounding
def compute_user_closeness_centrality(network, user, mode, weighted):
  if weighted:
    # if weights are requested, we should use the inverse of weights, since higher weights
    # means more interactions between two users
    weights = [1.0/w for w in network.es['weight']]
  else:
    weights = None
  user_closeness_centrality = network.closeness(vertices = user,
                                                mode = mode,
                                                weights = weights)
  return utils.round_to_sigfigs(user_closeness_centrality, NUM_SIGFIGS)


# computes all the network metrics for the input network. Each worker process will run
# this function for a different network. The input is the full location of the network
# file in Pickle format.
def compute_network_metrics(network_info):
  # whether the input networks are directed or not?
  directed_networks = args.directed_networks

  # name of the file is used as network name. It is assumed that file name takes the name
  # of the coin network if the networks are associated with each coin and we want to
  # compute active user metrics.
  network_name = network_info[1]
  network = igraph.Graph.Read_Pickle(network_info[0])

  result = [network_name]
  if not args.skip_general_metrics:
    num_vertices = len(network.vs)
    num_edges = len(network.es)
    unweighted_density = compute_network_unweighted_density(network)
    weighted_density = compute_network_weighted_density(network, directed_networks)
    unweighted_diameter = network.diameter(directed = directed_networks)
    weighted_diameter = compute_network_weighted_diameter(network, directed_networks)
    average_path_length = compute_network_average_path_length(network, directed_networks)
    clustering_coefficient = compute_network_clustering_coefficient(network)
    average_degree = compute_network_average_degree(network)

    result.extend([num_vertices, num_edges,
                   unweighted_density, weighted_density,
                   unweighted_diameter, weighted_diameter,
                   average_path_length, clustering_coefficient, average_degree])
  
  # user metrics requested?
  if args.users_input_file:
    # Read in mapping from coin name to list of (active user, num mentions).
    (max_num_coin_users,
     coin_users,
     coin_earliest_trade_dates,
     coin_earliest_mention_dates,
     coin_network_dates) = read_coin_users(args.users_input_file)

    if network_name not in coin_users:
      print 'Coin ' + network_name + ' is not in coin_users. Skipping'
      return 
    if network_name not in coin_earliest_trade_dates:
      print 'Coin ' + network_name + ' is not in coin_earliest_trade_dates. Skipping'
      return 
    if network_name not in coin_earliest_mention_dates:
      print 'Coin ' + network_name + ' is not in coin_earliest_mention_dates. Skipping'
      return 
    if network_name not in coin_network_dates:
      print 'Coin ' + network_name + ' is not in coin_network_dates. Skipping'
      return

    earliest_trade_date = coin_earliest_trade_dates[network_name]
    earliest_mention_date = coin_earliest_mention_dates[network_name]
    network_date = coin_network_dates[network_name]
    result.extend([earliest_trade_date, earliest_mention_date, network_date])

    # number of user-specific fields. Must update this number if you add a new field
    num_user_fields = 21 if directed_networks else 13
    users = coin_users[network_name]
    for i in range(0, max_num_coin_users):
      # if already consumed all active users, add empty fields
      if i >= len(users):
        if directed_networks:
          result.extend([""]*num_user_fields)
        else:
          result.extend([""]*num_user_fields)
        continue


      user = users[i][0]
      # number of times active user mentioned the coin
      user_num_mentions = int(users[i][1])
      user_num_posts = int(users[i][2])
      user_num_subjects = int(users[i][3])
      user_days_since_first_post = int(users[i][4])
      user_degree = network.degree(user, igraph.ALL)
      user_clustering_coefficient = compute_user_clustering_coefficient(
          network, user)
      user_closeness_centrality_unweighted = compute_user_closeness_centrality(
          network, user, igraph.ALL, False)
      user_closeness_centrality_weighted = compute_user_closeness_centrality(
          network, user, igraph.ALL, True)
      user_pagerank_unweighted = compute_user_pagerank(
          network, user, directed_networks, False)
      user_pagerank_weighted = compute_user_pagerank(
          network, user, directed_networks, True)
      # betweenness take a very long time, so it can be commented out
      user_betweenness_centrality_weighted = compute_user_betweenness_centrality(
          network, user, directed_networks, True)

      if directed_networks:
        user_degree_incoming = network.degree(user, igraph.IN)
        user_degree_outgoing = network.degree(user, igraph.OUT)
        user_closeness_centrality_incoming_unweighted = compute_user_closeness_centrality(
            network, user, igraph.IN, False)
        user_closeness_centrality_outgoing_unweighted = compute_user_closeness_centrality(
            network, user, igraph.OUT, False)
        user_closeness_centrality_incoming_weighted = compute_user_closeness_centrality(
            network, user, igraph.IN, True)
        user_closeness_centrality_outgoing_weighted = compute_user_closeness_centrality(
            network, user, igraph.OUT, True)

        # compute the shortest path from Satoshi to user of the coin. This would
        # give us a measure of how important the user is. So source is satoshi,
        # target is the user. weights should be None, so that weights get ignored
        # and all edges receive the same weight of 1. mode should be 'OUT', so that only
        # outgoing edges from each node are considered for getting from source to target.
        user_satoshi_distance = compute_user_satoshi_distance(network, user)
        user_satoshi_pagerank_unweighted = compute_user_satoshi_pagerank(network, user, False)
        user_satoshi_pagerank_weighted = compute_user_satoshi_pagerank(network, user, True)
        user_info = [user,
                     user_num_mentions,
                     user_num_posts,
                     user_num_subjects,
                     user_days_since_first_post,
                     user_degree,
                     user_degree_incoming,
                     user_degree_outgoing,
                     user_clustering_coefficient,
                     user_closeness_centrality_unweighted,
                     user_closeness_centrality_weighted,
                     user_closeness_centrality_incoming_unweighted,
                     user_closeness_centrality_outgoing_unweighted,
                     user_closeness_centrality_incoming_weighted,
                     user_closeness_centrality_outgoing_weighted,
                     user_betweenness_centrality_weighted,
                     user_satoshi_distance,
                     user_satoshi_pagerank_unweighted,
                     user_satoshi_pagerank_weighted,
                     user_pagerank_unweighted,
                     user_pagerank_weighted]
        result.extend(user_info)
      else:
        user_laplacian_centrality = compute_laplacian_centrality(
            network, user)
        user_info = [user,
                     user_num_mentions,
                     user_num_posts,
                     user_num_subjects,
                     user_days_since_first_post,
                     user_degree,
                     user_clustering_coefficient,
                     user_closeness_centrality_unweighted,
                     user_closeness_centrality_weighted,
                     user_betweenness_centrality_weighted,
                     user_laplacian_centrality,
                     user_pagerank_unweighted,
                     user_pagerank_weighted]
        result.extend(user_info)

      if len(user_info) != num_user_fields:
        sys.stderr.write('Error: Number of generated fields (%d) does not match expected '
                         '(%d). Did you forget to update expected num_fields?\n' %
                         (len(user_info), num_user_fields))
        return

  print 'Finished computing metrics for network: ' + network_name
  return result


def main():
  if not os.path.isdir(args.networks_input_dir):
    sys.exit('Could not find input directory %s.' % args.networks_input_dir)

  if args.users_input_file and not os.path.isfile(args.users_input_file):
    sys.exit('Could not find %s in input directory %s.'
             % (args.users_input_file, args.networks_input_dir))

  csvwriter = csv.writer(open(args.output_file, 'w'), delimiter=',')

  # First prepare header
  header = ["coin"]
  if not args.skip_general_metrics:
    header.extend(["num_vertices", "num_edges",
                   "unweighted_density", "weighted_density",
                   "unweighted_diameter", "weighted_diameter",
                   "average_path_length", "clustering_coefficient", "average_degree"])

  # Keeps track of all input filenames along with their network name in a list, so that it
  # can be used as input to pool of workers
  networks_info = list()
  # user metrics requested? but they are different for directed and undirected graphs.
  if args.users_input_file:
    # metrics are computed per coin
    (max_num_coin_users,
     coin_users,
     coin_earliest_trade_dates,
     coin_earliest_mention_dates,
     coin_network_dates) = read_coin_users(args.users_input_file)

    # Determine filenames (dates) corresponding to each coin
    for coin, coin_network_date in coin_network_dates.iteritems():
      network_file = os.path.join(args.networks_input_dir, coin_network_date)
      network_name = coin
      if not os.path.isfile(network_file):
        sys.stderr.write('File %s corresponding to coin %s does not exist.\n' %
                         (network_file, coin))
        continue
      networks_info.append((network_file, network_name))

    # Extend header since user metrics are requested.
    header.extend(["earliest_trade_date", "earliest_mention_date", "network_date"])
    for i in range(1, max_num_coin_users + 1):
      user = "user" + str(i)
      if args.directed_networks:
        header.extend([user,
                       user + "_num_mentions",
                       user + "_num_posts",
                       user + "_num_subjects",
                       user + "_days_since_first_post",
                       user + "_degree_total",
                       user + "_degree_incoming",
                       user + "_degree_outgoing",
                       user + "_clustering_coefficient",
                       user + "_closeness_centrality_unweighted",
                       user + "_closeness_centrality_weighted",
                       user + "_closeness_centrality_incoming_unweighted",
                       user + "_closeness_centrality_outgoing_unweighted",
                       user + "_closeness_centrality_incoming_weighted",
                       user + "_closeness_centrality_outgoing_weighted",
                       user + "_betweenness_centrality_weighted",
                       user + "_satoshi_distance",
                       user + "_satoshi_pagerank_unweighted",
                       user + "_satoshi_pagerank_weighted",
                       user + "_pagerank_unweighted",
                       user + "_pagerank_weighted"])
      else:
        header.extend([user,
                       user + "_num_mentions",
                       user + "_num_posts",
                       user + "_num_subjects",
                       user + "_days_since_first_post",
                       user + "_degree",
                       user + "_clustering_coefficient",
                       user + "_closeness_centrality_unweighted",
                       user + "_closeness_centrality_weighted",
                       user + "_betweenness_centrality_weighted",
                       user + "_laplacian_centrality",
                       user + "_pagerank_unweighted",
                       user + "_pagerank_weighted"])
  else:
    # metrics are computed per date
    for input_file in os.listdir(args.networks_input_dir):
      network_file = os.path.join(args.networks_input_dir, input_file)
      network_name = input_file

      if os.path.isdir(network_file):
        sys.stderr.write('Encountered a directory %s in input directory.' % network_file)
        continue

      # Skip the coin active/introducer users file
      if '.csv' in network_file:
        continue

      networks_info.append((network_file, network_name))


  csvwriter.writerow(header)

  # now apply all network files to the pool of workers
  pool = multiprocessing.Pool(processes = args.num_processes)
  all_network_metrics = pool.map(compute_network_metrics, networks_info)

  for network_metrics in all_network_metrics:
    # for invalid networks, network_metrics is an empty list
    if network_metrics:
      csvwriter.writerow(network_metrics)


if __name__ == '__main__':
  main()
