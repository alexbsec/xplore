require 'open-uri'
require 'net/http'
require 'colorize'

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
            'large' => 'https://wordlists-cdn.assetnote.io/data/manual/aspx_lowercase.txt'
        },
        'html' => {
            'large' => 'https://wordlists-cdn.assetnote.io/data/manual/html.txt'
        },
        'xml' => {
            'large' => 'https://wordlists-cdn.assetnote.io/data/manual/xml_filenames.txt'
        }
    }

    def initialize(url, gcode, type, size, output)
        url = url.start_with?('https://') ? url.chomp('/') : "https://#{url.chomp('/')}"
        url += "/" unless url.end_with?("/")
        @url = url
        @gcode = gcode
        @output = output


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
    end


    def get_status_code(url)
        uri = URI(url)
        response = Net::HTTP.get_response(uri)
        response.code.to_i
    end

    def save_output(output_file, content)
        File.open(output_file, 'a') do |file|
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

    def process_output_files
        Dir.glob("./*.txt") do |path|
            lines = read_file(path)
            unique_lines = remove_duplicate(lines)
            File.open(path, "w") do |file|
                file.puts(unique_lines)
            end
        end
    end

    def request
        uri = URI.parse(WORDLISTS[@type][@size])
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            req = Net::HTTP::Get.new(uri.request_uri)
            http.request(req) do |response|
                response.body.each_line do |word|
                    word.chomp!
                    begin
                        url = "#{@url}#{word}"
                        status = get_status_code(url)
                        if status && @gcode.include?(status)
                            color = case status.to_s
                                    when /^2\d{2}$/ then :green
                                    when /^3\d{2}$/ then :yellow
                                    when /^4\d{2}$/ then :red
                                    when /^5\d{2}$/ then :orange
                                    else :white
                                    end
                            puts "#{url}".ljust(120) + "[#{status}]".colorize(color)
                            if !@output.nil?
                                status_file = "#{@output}-#{status}.txt"
                                save_output(status_file, url)
                            end
                        end
                    rescue URI::InvalidURIError => e
                        puts "Invalid URI: #{url}. Skipping...".red
                        next
                    end
                end
            end
        end
    end
end
