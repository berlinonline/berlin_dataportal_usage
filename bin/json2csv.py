import csv
import json
import argparse

default_in_path = 'data/current/daten_berlin_de.stats.json'
default_out_path = 'data/current/daten_berlin_de.domain_stats.csv'

parser = argparse.ArgumentParser(description="Extract the monthly totals from the JSON stats file and write to a CSV file.")
parser.add_argument('-i', '--infile', default=default_in_path,
                    help=f"The path to the input JSON file. Default is {default_in_path}.")
parser.add_argument('-o', '--outfile', default=default_out_path,
                    help=f"The path to the output CSV file. Default is {default_out_path}.")
args = parser.parse_args()

with open(args.infile) as json_file:
    data = json.load(json_file)

header = [ "month", "impressions","visits", "visit_duration_avg_seconds" ]
rows = [ 
    [key, month['impressions'], month['visits'], month['visit_duration_avg']]
    for
    key, month in data['stats']['totals'].items()
]

with open(args.outfile, 'w') as csv_file:
    csv_writer = csv.writer(csv_file, lineterminator="\n")
    csv_writer.writerow(header)
    for row in rows:
        csv_writer.writerow(row)
