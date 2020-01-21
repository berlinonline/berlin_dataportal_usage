require 'csv'
require 'date'
require 'json'
require 'logger'
require 'active_support'
require 'active_support/core_ext'

class StatsExporter
    def initialize(conf)
        @logger = Logger.new(STDERR)
        if (append_path = conf[:append_path])
            @logger.info("Appending stats to #{append_path} ...")
            old_stats = JSON.parse(File.read(append_path), {:symbolize_names => true})
            @stats = old_stats[:stats]
            @stats[:site_uri] = conf[:stats][:site_uri]
            @stats[:earliest] = conf[:stats][:earliest]
            @stats[:latest] = conf[:stats][:latest]
            @stats[:totals] = conf[:stats][:totals]
            conf[:stats][:pages][:datensaetze][:sub_page_counts].each do |month, counts|
                @logger.info("Appending counts for #{month} ...")
                @stats[:pages][:datensaetze][:sub_page_counts][month.to_sym] = counts
            end
            @stats[:pages][:datensaetze][:latest] = conf[:stats][:pages][:datensaetze][:latest]
            @stats[:pages][:datensaetze][:sub_page_counts] = Hash[@stats[:pages][:datensaetze][:sub_page_counts].sort { |a, b| b <=> a}]
        else
            @logger.info("Overwriting stats file ...")
            @stats = conf[:stats]
        end
    end

    def domain_stats_table
        @stats[:totals].transform_values { |v| [ v[:impressions], v[:visits] ] }.to_a.map { |x| x.flatten }
    end

    def stats_table(pagename)
        page_index = {}
        @stats[:pages][pagename][:sub_page_counts].each_pair do |month, stats|
            stats.each_pair do |page, numbers|
                page_index[page] = {} unless page_index[page]
                page_index[page][month] = numbers
            end
        end

        start_date = Date.iso8601(@stats[:pages][pagename][:earliest])
        end_date = Date.iso8601(@stats[:pages][pagename][:latest])
        
        table = []
        header_row = [ 'page' ]
        date = start_date
        while (date <= end_date)
            month = date.strftime("%Y-%m")
            header_row << "#{month} pi"
            header_row << "#{month} pv"
            date = date.next_month
        end
        table << header_row

        page_index.each_pair do |page, month_stats|
            row = [ page ]
            date = start_date
            while (date <= end_date)
                month = date.strftime("%Y-%m")
                if (stats = month_stats[month.to_sym])
                    row << stats[:impressions]
                    row << stats[:visits]
                else
                    row << nil
                    row << nil
                end
                date = date.next_month
            end
            table << row
        end

        return table
    end

    def stats_tables
        tables = {}
        @stats[:pages].keys.each do |path|
            tables[path] = stats_table(path)
        end
        return tables
    end


    def to_json
        {
            :timestamp => Time.now ,
            :source => "WebTrekk" ,
            :stats => @stats
        }
    end

    def StatsExporter.month_limits(month)
        {
            :first => Date.new(month.year, month.month, 1) ,
            :last => month.end_of_month
        }
    end

    def StatsExporter.month_list(start_date, end_date)
        months = []
        current_date = end_date
        while (current_date >= start_date)
            months << StatsExporter.month_limits(current_date)
            current_date = current_date.prev_month
        end
        months
    end

end