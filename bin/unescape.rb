require 'cgi'

filename = ARGV[0]
File.open(filename).each { |line| puts CGI.unescape(line) }