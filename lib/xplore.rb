require 'optparse'
require_relative 'xplore/requests'
require 'colorize'


def check_gcode_input(input)
    if input.is_a?(Integer)
        return input
    end

    if input.match?(/\A\d+\z/)
        return input.to_i
    elsif input.match?(/\A[a-zA-Z]+\z/)
        return input
    else
        return nil
    end
end

def check_gcode_status(input)
    if input.match?(/\A\d{1,3}(,\d{3})*\z/)
        return true
    end
    return false
end

def main()
    flags = {}
    positional_arg_list = %w[php asp aspx html config ui_config xml general simple js routes apache nginx]
    flags[:gcode] = 200
    flags[:delay] = 100

    OptionParser.new do |opts|
        opts.banner = "Usage: xplore [options] [flags]"
        opts.on("-u URL", '--url URL', "Specify the target URL") do |url|
            flags[:url] = url
        end
        opts.on("-g STATUS-CODE", '--grep-code STATUS-CODE', "Specify which status code should not be ignored. Type all to grep all status code. Default is 200 (can be a list).") do |gcode|
            flags[:gcode] = gcode
        end
        opts.on("-o SAVE-OUTPUT", '--output', "Set this flag with a name to save the results in a .txt file.") do |output|
            flags[:output] = output
        end
        opts.on("-d DELAY", '--delay DELAY', "Set the delay in miliseconds between requests. Default is 100.") do |delay|
            flags[:delay] = delay
        end
        opts.on("-s", "--small", TrueClass, "Set the scan to use small wordlist. Default is false.")
    end.parse!(into: flags)
    
    
    if ARGV.empty?
        puts "Please specify a positional argument: [php|asp|aspx|html|config|ui_config|massive|general|apache|nginx|js|routes]"
        exit
    end
    
    mode = ARGV[0]
    
    if mode && !positional_arg_list.include?(mode)
        puts "Invalid option: #{mode}. Please use one of the following: #{positional_arg_list}"
        exit
    end

    url = flags[:url]
    output = flags[:output]
    delay = flags[:delay].to_i

    if url.nil?
        puts "Missing url flag (-u)".red
        exit
    end

    use_small = flags[:small]
    gcode = flags[:gcode]
    gcode_check = check_gcode_input(gcode)

    if use_small.nil?
        use_small = false
    end

    if gcode_check.nil?
        gcode_good = check_gcode_status(gcode)
        if !gcode_good
            puts "Grep code format (#{gcode}) does not match expected."
            exit
        else
            gcode = gcode.split(',').map(&:to_i).compact
        end
    elsif gcode_check.is_a?(Integer)
        gcode = [gcode_check]
    elsif gcode != 'all'
        puts "Grep code format (#{gcode}) does not match expected."
        exit
    end

    xplore = Xplore.new(url, gcode, mode, "small", output, delay)
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
    puts "PARAMETERS".center(63,'-')
    puts "---------------------------------------------------------------"
    puts "Xplore list mode " +  "#{mode}".green
    puts "Grep status code " + "#{gcode}".green
    puts "Delay is " + "#{delay} milisec".green
    puts "Starting to \033[1mXplore\033[0m".center(70, '=')
    xplore.request
    xplore.process_output_files

end

main()