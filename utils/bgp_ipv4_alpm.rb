require 'bgp4r'
require 'yaml'
include BGP

require 'pp'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on('-a', '--afi', 'Address Family') { |v| options[:afi] = v }
  opts.on('-s', '--safi', 'Source host') { |v| options[:safi] = v }
  opts.on('-n', '--number', 'number of prefixes') { |v| options[:@times] = v }

end.parse!

dest_options = YAML.load_file('destination_config.yaml')
puts dest_options['']

v4prefixes = 10
v6prefixes = 10

neighbor = Neighbor.new \
  :version => 4,
  :my_as=> 600,
  :remote_addr => 210.3.2.3,
  :local_addr => 210.3.2.6,
  :id=> 3.3.3.3,
  :holdtime=> 180

# neighbor.capability :as4_byte

pav4 = Path_attribute.new(
  Origin.new("0"),
  Next_hop.new("210.3.2.6"),
  Local_pref.new("200"),
  Communities.new(*("100:1 200:1 300:1 2938:22 324:3432 3344:343 4466:6436 5445:3454 3545:5677 5754:5754".split.map { |com| com.to_i})),
  As_path.new(*("790 90 80 2334 544 56 67 889 3111 777 8 879 0900 88 7654 3211 113 43434 666 343 4534 667 7688".split.map { |as| as.to_i}))
)

pav6 = Path_attribute.new(
    Origin.new("0"),
    Next_hop.new("::6"),
    Local_pref.new("200"),
    Communities.new(*("100:1 200:1 300:1 2938:22 324:3432 3344:343 4466:6436 5445:3454 3545:5677 5754:5754".split.map { |com| com.to_i})),
    As_path.new(*("790 90 80 2334 544 56 67 889 3111 777 8 879 0900 88 7654 3211 113 43434 666 343 4534 667 7688".split.map { |as| as.to_i}))
)




neighbor.start


@nlri4 = IPAddr.new "20.0.0.0/28"

nlris = Nlri.new
(1..@times.to_i).each do |n|
  pp 'mz -c 3 -B %s -t udp dp=999 -A 210.4.2.5 &' % (IPAddr.new(@nlri4 ^ n) + 1)
  pp 'sleep 2' if (n % 500) == 0
  nlris << (@nlri4 ^ n)
  next unless (n % @pack) == 0 or (n == @times)
  neighbor.send_message Update.new(pav4, nlris)
  nlris = Nlri.new
end

=begin

@nlri6 = IPAddr.new "5000:9999:8888:1::0/64"
(1..@times.to_i).each do |n|
  nlris << (@nlri6 ^ n)
  next unless (n % @pack) == 0 or (n == @times)
  neighbor.send_message Update.new(pav4, nlris)
  nlris = Nlri.new
end
=end

sleep(1800)

=begin
require 'bgp4r'
require 'yaml'
include BGP
v4prefixes = 10
v6prefixes = 10

require 'pp'
@times = 10
@pack = 127

@nlri4 = IPAddr.new "20.0.0.0/28"
(1..@times.to_i).each do |n|
pp 'mz -c 3 -B %s -t udp dp=999 -A 210.4.2.5 &' % (IPAddr.new(@nlri4 ^ n) + 1)
pp 'sleep 2' if (n % 3) == 0
next unless (n % 127) == 0 or (n== @times)
end

@nlri6 = IPAddr.new "5000:9999:8888:1::0/64"
(1..@times.to_i).each do |n|
#  nlris << (@nlri6 ^ n)

  next unless (n % @pack) == 0 or (n == @times)
#  neighbor.send_message Update.new(pav4, nlris)
#  nlris = Nlri.new
end



=end


