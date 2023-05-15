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

    def initialize(url, gcode, type, size)
        url = url.start_with?('https://') ? url.chomp('/') : "https://#{url.chomp('/')}"
        url += "/" unless url.end_with?("/")
        @url = url
        @gcode = gcode


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

    
    def request
        uri = URI.parse(WORDLISTS[@type][@size])
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            req = Net::HTTP::Get.new(uri.request_uri)
            http.request(req) do |response|
                response.body.each_line do |word|
                    word.chomp!
                    status = get_status_code("#{@url}#{word}")
                    if status && @gcode.include?(status)
                        color = case status.to_s
                                when /^2\d{2}$/ then :green
                                when /^3\d{2}$/ then :yellow
                                when /^4\d{2}$/ then :red
                                when /^5\d{2}$/ then :orange
                                else :white
                                end
                        puts "#{@url}#{word}".ljust(70) + "[#{status}]".colorize(color)
                    end
                end
            end
        end
    end
end
