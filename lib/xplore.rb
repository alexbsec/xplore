require 'net/http'
require 'optparse'



def main()
    flags = {}
    positional_arg_list = %w[php asp aspx html config ui_config massive general simple js routes]
    
    OptionParser.new do |opts|
        opts.banner = "Usage: prog.rb [options] [php|asp|aspx|html|config|ui_config|massive|general|simple|js|routes] [flags] [-u url | -g grep status code | -s small wordlist]"
        opts.on("-u URL", '--url URL', "Specify the target URL") do |url|
            flags[:url] = url
        end
        opts.on("-g STATUS-CODE", '--grep-code STATUS-CODE', "Specify which status code should not be ignored. Default is 200 (can be a list).") do |gcode|
            flags[:gcode] = gcode
        end
        opts.on("-s", "--small", TrueClass, "Set the scan to use small wordlist. Default is false.")
    end.parse!(into: flags)
    
    
    if ARGV.empty?
        puts "Please specify a positional argument: [php|asp|aspx|html|config|ui_config|massive|general|simple|fast|js|routes]"
        exit
    end
    
    mode = ARGV[0]
    
    if mode && !positional_arg_list.include?(mode)
        puts "Invalid option: #{mode}. Please use one of the following: #{positional_arg_list}"
        exit
    end

    url = flags[:url]
    use_small = flags[:small]
    gcode = flags[:gcode]
    if use_small.nil?
        use_small = false
    end



end

main()