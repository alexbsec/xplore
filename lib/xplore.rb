require 'net/http'
require 'optparse'


options = {}
options[:url] = ''

parser = OptionParser.new do |opts|
    opts.banner = "Usage: prog.rb [options] [php|asp|aspx|html|config|ui_config|massive|general|simple|fast|js|routes] [flags] [-u url]"
    opts.on("-u URL", '--url URL', "Specify the target URL") do |url|
        options[:url] = url
    end
end

parser.parse!

if ARGV.empty?
    puts "Please specify a positional argument: [php|asp|aspx|html|config|ui_config|massive|general|simple|fast|js|routes]"
    exit
end

positional_arg = ARGV[0]

puts "Positional argument: #{positional_arg}"
puts "URL: #{options[:url]}"

def get_status_code(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    response.code.to_i
end
