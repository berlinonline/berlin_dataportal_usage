require 'date'
require 'keychain'
require 'logger'
require 'optparse'
require 'uri'
require 'active_support'
require 'active_support/core_ext'
require 'webtrekk_connector'

require_relative '../lib/stats_exporter.rb'

require 'pp'

logger = Logger.new(STDERR)

options = {
    :endpoint => "https://report27.webtrekk.com/cgi-bin/wt/JSONRPC.cgi" , 
    :all_months => false ,
    :replace => false ,
}

usage = "Usage: ruby #{ __FILE__} [options] CONF.JSON OUTPATH"
OptionParser.new do |opts|
  opts.banner = usage
  opts.separator ""
  opts.separator "Options:"

  opts.on("-e", "--endpoint STRING", String, "The domain of the Webtrekk API endpoint. Used for getting password out of keychain.") do |endpoint|
    options[:endpoint] = endpoint
  end

  opts.on("-a", "--[no-]all_months", "For the per-dataset stats, get all months (instead of just the previous month).") do |all_months|
    options[:all_months] = all_months
  end

  opts.on("-r", "--[no-]replace", "Replace the stats files instead of appending.") do |replace|
    options[:replace] = replace
  end

end.parse!

out_dir = ARGV.pop
conf_path = ARGV.pop
unless conf_path
  puts usage
  exit
end

# get username and password from OS X keychain
keychain_item = Keychain.internet_passwords.where(:server => URI(options[:endpoint]).host).first

unless keychain_item
    puts "No internet password for server #{options[:endpoint]} found, cannot proceed."
    exit
end

options[:user] = keychain_item.account
options[:pwd] = keychain_item.password

config = JSON.parse(File.read(conf_path))
connector = WebtrekkConnector.new(options)
connector.login

stats = {
  :site_uri => config['site_uri'] ,
  :earliest => config['startDate'][0..6] ,
  :latest => Date.today.prev_month.end_of_month.iso8601[0..6] ,
  :pages => {
    :datensaetze => {
      :earliest => config['startDate'] ,
      :latest => Date.today.prev_month.end_of_month.iso8601 ,
      :page_uri => config['per_dataset_analysis']['analysisFilter']['filterRules'].first['filter']
    }
  }
}

# get domain stats
config['domain_analysis']['startTime'] = Date.iso8601(config['startDate'])
config['domain_analysis']['stopTime'] = Date.today.prev_month.end_of_month.iso8601
domain_analysis = connector.request_analysis(config['domain_analysis'])
stats[:totals] = domain_analysis['analysisData'].reverse.map { |entry| [ entry[0] , { :impressions => entry[2].to_i , :visits => entry[1].to_i } ] }.to_h

sub_page_totals = {}

# get per-dataset stats
last = Date.today.prev_month
first = options[:all_months] ? Date.iso8601(config['startDate']) : last
months = StatsExporter.month_list(first, last)
months.each do |month|
  index = month[:first].iso8601[0..6]
  logger.info("getting stats for #{index} ...")
  config['per_dataset_analysis']['startTime'] = month[:first]
  config['per_dataset_analysis']['stopTime'] = month[:last]
  result = connector.request_analysis(config['per_dataset_analysis'])
  sub_page_totals[index] = result['analysisData'].map { |entry| [ entry[0].split("/").last.to_sym , { :impressions => entry[2].to_i , :visits => entry[1].to_i } ] }.to_h
end

stats[:pages][:datensaetze][:sub_page_counts] = sub_page_totals

site_uri = config['site_uri'].gsub(".", "_")
json_out_file = "#{site_uri}.stats.json"
json_out_file = File.join(out_dir, json_out_file)

exporter_conf = {:stats => stats}
exporter_conf[:append_path] = json_out_file unless options[:replace]
exporter = StatsExporter.new(exporter_conf)

File.open(json_out_file, "wb") do |file|
  file.puts JSON.pretty_generate(exporter.to_json)
end

csv_out_file = "#{site_uri}.domain_stats.csv"
csv_out_file = File.join(out_dir, csv_out_file)
CSV.open(csv_out_file, "wb") do |csv|
  csv << [ "month", "impressions", "visits" ]
  exporter.domain_stats_table.each do |row|
      csv << row
  end
end

exporter.stats_tables.each_pair do |pagename, stats_table|
  csv_out_file = "#{site_uri}.page_stats.#{pagename}.csv"
  csv_out_file = File.join(out_dir, csv_out_file)
  CSV.open(csv_out_file, "wb") do |csv|
      stats_table.each do |row|
          csv << row
      end
  end
end
