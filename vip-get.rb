#                   _____                 ___            _ 
#     ___  __   __ |___ /   _ __   ___   / _ \   _   _  / |
#    / _ \ \ \ / /   |_ \  | '__| / __| | | | | | | | | | |
#   |  __/  \ V /   ___) | | |    \__ \ | |_| | | |_| | | |
#    \___|   \_/   |____/  |_|    |___/  \___/   \__,_| |_|
#                                                          
#             Created by ev3rs0u1 on 2017/3/2.
require 'net/http'
require 'nokogiri'

def http_get(url, params: {}, headers: {})
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  req = Net::HTTP.new(uri.host, uri.port)
  req.get(uri.request_uri, headers)
end

def human(size)
  units = %w(B KB MB GB TB)
  e = (Math.log(size.to_i) / Math.log(1024)).floor
  %(%.2f%s) % [(size.to_f / 1024 ** e), units[e]]
end

def usage_help
  name = $0.split('/')[-1].split('.')[0]
  puts "Usage: #{name} [page] [level=<bq, gq, cq, yh>] (default=bq)"
  puts "Example: #{name} http://www.iqiyi.com/v_19rrac4x2k.html gq"
end

def vip_get(page, level)
  api_url = 'http://aikan-tv.com/url.php'
  params = { xml: page, type: 'auto', hd: level }
  res = http_get(api_url, params: params)
  raise Exception, 'parameter page invalid' if res.body.size < 50
  xml_doc = Nokogiri::XML(res.body)
  mash =-> (x) { [x.css('file').text, x.css('size').text] }
  list = xml_doc.css('video').map(&mash).sort_by(&:last).max_by(&:last)
  puts "Url: [#{list[0]}]\nSize: [#{human(list[1])}]\n\n"
  print "[Play it? (Y/n)]: "; opt = STDIN.gets
  cmd = %(mpv.exe "#{list[0]}")
  ['y', 'Y', "\n"].include?(opt) ? IO.popen(cmd) : raise(Exception, 'invalid option')
end

def main
  page = ARGV[0]
  level = (ARGV[1] ||= 'bq')
  (page.nil? || level.nil?) ? usage_help : vip_get(page, level)
rescue Interrupt
  puts 'EXIT!'
rescue Exception => e
  puts "Error: #{e.message}"
end

if __FILE__ == $0
  main
end
