'''
A script to replace old package/dataset names in the usage data with the new ones.

See https://github.com/berlinonline/berlin_dataset_name_mapping
'''

import csv
import urllib.request
import json
import logging
import sys
from datetime import datetime

logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger(__name__)

def sum_stats(stat_1: dict, stat_2: dict) -> dict:
    sum = {}
    sum['impressions'] = stat_1['impressions'] + stat_2['impressions']
    sum['visits'] = stat_1['visits'] + stat_2['visits']
    return sum

mapping_url = "https://raw.githubusercontent.com/berlinonline/berlin_dataset_name_mapping/refs/heads/main/dataset_name_mapping.2024-09-06.csv"
response = urllib.request.urlopen(mapping_url)
LOG.info(f" reading dataset name mappings from {mapping_url} ...")
lines = [l.decode('utf-8') for l in response.readlines()]
reader = csv.DictReader(lines)
mapping = {}

for row in reader:
    mapping[row['old_name']] = row['new_name']

usage_data_path = "data/current/daten_berlin_de.stats.json"
if len(sys.argv) > 1:
    usage_data_path = sys.argv[1]

LOG.info(f" reading usage data from {usage_data_path} ...")

with open(usage_data_path) as f:
    usage_data = json.load(f)

sub_page_counts = usage_data['stats']['pages']['datensaetze']['sub_page_counts']

LOG.info(" normalising dataset names in usage data ...")
updated_usage_data = {}
for date, ids in sub_page_counts.items():
    updated_usage_data[date] = {}
    for current_package_name, stats in ids.items():
        new_package_name = mapping.get(current_package_name, current_package_name)
        if new_package_name in updated_usage_data[date]:
            stats = sum_stats(stats, updated_usage_data[date][new_package_name])
        updated_usage_data[date][new_package_name] = stats

usage_data['stats']['pages']['datensaetze']['sub_page_counts'] = updated_usage_data
usage_data['timestamp'] = datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %z')

print(json.dumps(usage_data, indent=2))