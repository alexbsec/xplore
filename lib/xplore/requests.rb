require 'open-uri'
require 'net/http'
require 'colorize'
require 'terminal-table'
require 'socket'

class Xplore
    attr_reader :words
    WORDLISTS = {
        'php' => {
            'small' => 'https://wordlists-cdn.assetnote.io/data/manual/phpmillion.txt',
            'large' => 'https://wordlists-cdn.assetnote.io/data/manual/php.txt'
        },
        'asp' => {
            'small' => 'https://wordlists-cdn.assetnote.io/data/manual/asp_lowercase.txt',
        },
        'aspx' => {
            'small' => 'https://wordlists-cdn.assetnote.io/data/manual/aspx_lowercase.txt'
        },
        'html' => {
            'small' => 'https://wordlists-cdn.assetnote.io/data/manual/html.txt'
        },
        'xml' => {
            'small' => 'https://wordlists-cdn.assetnote.io/data/manual/xml_filenames.txt'
        },
        'general' => {
            'small' => 'https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/combined_words.txt'
        },
        'apache' => {
            'small' => 'https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/apache.txt',
            'large' => 'https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/Apache.fuzz.txt'
        },
        'nginx' => {
            'small' => 'https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/nginx.txt'
        },
        'routes' => {
            'small' => 'https://wordlists-cdn.assetnote.io/data/automated/httparchive_apiroutes_2022_09_28.txt'
        }
    }


    def miliseconds_to_seconds(t)
        return t/1000
    end


    def initialize(url, gcode, type, size, output, delay)
        url = url.start_with?('https://') ? url.chomp('/') : "https://#{url.chomp('/')}"
        url += "/" unless url.end_with?("/")
        @url = url
        @gcode = gcode
        @output = output
        @delay = miliseconds_to_seconds(delay)

        if @gcode == 'all'
            @gcode = [100, 101, 102, 103, 200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300,
            301, 302, 303, 304, 305, 306, 307, 308, 400, 401, 402, 403, 404, 405, 406,
            407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423,
            424, 426, 428, 429, 431, 451, 500, 501, 502, 503, 504, 505, 506, 507, 508,
            510, 511
          ]
        end

        case type.downcase
        when "php", "asp", "aspx", "html", "config", "ui_config", "general", "js", "routes"
            @type = type.downcase
        else
            raise "Invalid wordlist type #{type}"
        end

        case size.downcase
        when "small"
            @size = "small"
        when "large"
            @size = "large"
        end

        if !output.nil?
            create_out_dir(output)
        end
    end


    def get_status_code(url)
        uri = URI(url)
        response = Net::HTTP.get_response(uri)
        response.code.to_i
    end

    def save_output(path, content)
        File.open(path, 'a') do |file|
            file.puts content
        end
    end
        
    
    def read_file(path)
        File.readlines(path, chomp: true)
    rescue Errno::ENOENT
        []
    end

    def remove_duplicate(array)
        array.uniq
    end

    def create_out_dir(name)
        Dir.mkdir(name)
    rescue Errno::EEXIST
        nil
    end        

    def process_output_files
        Dir.glob("#{@output}/*.txt") do |path|
            lines = read_file(path)
            unique_lines = remove_duplicate(lines)
            File.open(path, "w") do |file|
                file.puts(unique_lines)
            end
        end
    end

    def colorize_output(text)
        color = case text
        when /^2\d{2}$/ then :green
        when /^3\d{2}$/ then :blue
        when /^4\d{2}$/ then :red
        when /^5\d{2}$/ then :yellow
        else :white 
        end
        return color
    end


    def request
        begin
            uri = URI.parse(WORDLISTS[@type][@size])
            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
                req = Net::HTTP::Get.new(uri.request_uri)
                http.request(req) do |response|
                    response.body.each_line do |word|
                        word.chomp!
                        begin
                            sleep(@delay)
                            word = word.start_with?('/') ? word[1..-1] : word
                            url = "#{@url}#{word}"
                            status = get_status_code(url)
                            if status && @gcode.include?(status)
                                color = colorize_output(status.to_s)
                                table = Terminal::Table.new do |t|
                                    t.style = {border_x: '', border_i: ''}
                                    t.add_row [
                                        url,
                                        "[#{status}]".colorize(color)
                                    ]
                                end
                                puts table
                                if !@output.nil?
                                    status_file_path = "#{@output}/#{@output}-#{status}.txt"
                                    save_output(status_file_path, url)
                                end
                            end
                        rescue URI::InvalidURIError => e
                            puts "Invalid URI: #{url}. Skipping...".red
                            next
                        rescue SocketError => e
                            puts "Failed to establish TCP connection. Skipping...".red
                            next
                        end
                    end
                end
            end
        rescue Interrupt
            puts "\nXplore terminated by user".green
            exit 0
        end
    end
end
