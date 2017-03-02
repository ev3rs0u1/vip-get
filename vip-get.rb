# Created by ev3rs0u1 on 2017/3/2.
require 'net/http'
require 'nokogiri'
require 'terminal-table'

def http_get(url, params: {}, headers: {})
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  req = Net::HTTP.new(uri.host, uri.port)
  req.get(uri.request_uri, headers)
end

def human(size)
  isize = size.to_f
  return 'FULL' if isize < 1
  units = %w(B KB MB GB TB)
  e = (Math.log(isize) / Math.log(1024)).floor
  %(%.2f %s) % [(isize / 1024 ** e), units[e]]
end

def to_time(str)
  Time.at(str.to_i).utc.strftime("%H:%M:%S")
end

def print_table(rows)
  table = Terminal::Table.new
  table.headings = [{ value: 'FILESIZE', colspan: 2 }, 'TIME']
  table.rows = rows
  table.style = {
    border_x: '=',
    alignment: :center,
    all_separators: true
  }
  puts table
end

def vip_get(page, level)
  api_url = 'http://aikan-tv.com/url.php'
  params = { xml: page, type: 'auto', hd: level }
  res = http_get(api_url, params: params)
  raise Exception, 'parameter page invalid' if res.body.size < 50
  xml_doc = Nokogiri::XML(res.body)
  mash =-> (x) { [%("#{x.css('file').text}"), x.css('size').text, x.css('seconds').text] }
  list = xml_doc.css('video').map(&mash)
  rows = list.map.with_index { |(_, b, c), i| [i + 1, human(b), to_time(c)] }
  print_table(rows)
  cmd = %(mpv.exe #{list.map(&:first).join(' ')})
  print "[Play all? (Y/n)]: "; opt = STDIN.gets
  ['y', 'Y', "\n"].include?(opt) ? IO.popen(cmd) : raise(Interrupt)
end

def usage_help
  name = $0.split('/')[-1].split('.')[0]
  puts "Usage: #{name} [page] [level=<bq, gq, cq, yh>] (default=bq)"
  puts "Example: #{name} http://www.iqiyi.com/v_19rrac4x2k.html gq"
end

def main
  page = ARGV[0]
  level = (ARGV[1] ||= 'bq')
  (page.nil? || level.nil?) ? usage_help : vip_get(page, level)
rescue Interrupt
  puts 'EXIT!'
rescue Exception => e
  puts "Error: #{e}"
end

if __FILE__ == $0
  main
end
