require 'optparse'
require_relative 'xplore/requests'
require 'colorize'


def main()
    flags = {}
    positional_arg_list = %w[php asp aspx html config ui_config xml general simple js routes]
    flags[:gcode] = 200

    OptionParser.new do |opts|
        opts.banner = "Usage: prog.rb [options] [php|asp|aspx|html|config|ui_config|xml|simple|js|routes] [flags] [-u url | -g grep status code | -s small wordlist]"
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

    if url.nil?
        puts "Missing url flag (-u)".red
        exit
    end

    use_small = flags[:small]
    gcode = flags[:gcode]

    if use_small.nil?
        use_small = false
    end

    if gcode != 200
        gcode = gcode.split(',').map(&:to_i).compact
    else
        gcode = [200]
    end

    xplore = Xplore.new(url, gcode, mode, "small")
    puts %q{
        __    __            __                               
        /  |  /  |          /  |                              
        $$ |  $$ |  ______  $$ |  ______    ______    ______  
        $$  \/$$/  /      \ $$ | /      \  /      \  /      \ 
         $$  $$<  /$$$$$$  |$$ |/$$$$$$  |/$$$$$$  |/$$$$$$  |
          $$$$  \ $$ |  $$ |$$ |$$ |  $$ |$$ |  $$/ $$    $$ |
         $$ /$$  |$$ |__$$ |$$ |$$ \__$$ |$$ |      $$$$$$$$/ 
        $$ |  $$ |$$    $$/ $$ |$$    $$/ $$ |      $$       |
        $$/   $$/ $$$$$$$/  $$/  $$$$$$/  $$/        $$$$$$$/ 
                  $$ |                                        
                  $$ |                                        
                  $$/         
}.red
    puts "Starting to \033[1mXplore\033[0m".center(80, '=')
    xplore.request

end

main()