require 'net/http'
require 'net/https'
require 'uri'
require 'rubygems'
require 'json'

# tested and works with Ruby 1.8.7 and 1.9.3
if ARGV.length != 1
  $stderr.puts "Usage: ruby client.rb [ga|gd|gv]"
  exit(1)
end

if ARGV[0] != 'ga' and ARGV[0] != 'gd' and ARGV[0] != 'gv'
  $stderr.puts "Usage: ruby client.rb [ga|gd|gv]"
  exit(1)
end


teacs = $stdin.read
uri = URI.parse("https://cadhan.com/api/intergaelic/3.0")
https = Net::HTTP.new(uri.host, uri.port)
https.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri)
request.add_field('Content-Type', 'application/x-www-form-urlencoded')
request.set_form_data({'foinse' => ARGV[0], 'teacs' => teacs})
response = https.request(request)
if response.code == '200'
  begin
    parsed = JSON.parse(response.body)
  rescue JSON::ParserError => e
    $stderr.puts "Bad JSON response from server: #{e.message}"
    exit(1)
  end
  parsed.each { |x|
    puts x[0] + ' => ' + x[1]
  }
else
  $stderr.puts "Bad response code from server: #{response.code}"
end
