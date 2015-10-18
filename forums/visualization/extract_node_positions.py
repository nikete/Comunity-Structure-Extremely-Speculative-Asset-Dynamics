#!/usr/bin/python

import csv
import json
import argparse

parser = argparse.ArgumentParser(
    description='Gets a network json from cytoscape and extracts x and y position of '
                'nodes')
parser.add_argument('network_input',
                    help='The location of input json file containing network info '
                    'exported by cytoscpape.')
parser.add_argument('nodes_output',
                    help='The location of output csv file containing nodes and their '
                    'coordinates')
args = parser.parse_args()

if __name__ == '__main__':
  with open(args.network_input) as data_file:    
    data = json.load(data_file)

  with open(args.nodes_output, 'w') as csvfile:
    nodes_writer = csv.writer(csvfile, delimiter = ',')
    nodes_writer.writerow(['name', 'x', 'y'])
    
    for node in data['elements']['nodes']:
      name = node['data']['name'].encode('utf-8').strip()
      x_coord = node['position']['x']
      y_coord = node['position']['y']
      nodes_writer.writerow([name, x_coord, y_coord])
