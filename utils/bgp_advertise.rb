require 'bgp4r'
require 'yaml'
include BGP

require 'pp'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: bgp_ipv4_alpm.rb [options]"

  opts.on('-r', '--remote_addr IPADDR', 'Remote Address') { |v| options[:remote_add] = v }
  opts.on('-l', '--local_address IPADDR', 'Local address') { |v| options[:local_add] = v }
  opts.on('-a', '--local_as ASN', 'Local ASN') { |v| options[:local_as] = v }
  opts.on('-4', '--v4prefixes INTEGER', 'number of v4 prefixes') { |v| options[:times4] = v }
  opts.on('-6', '--v6prefixes INTEGER', 'number of v4 prefixes') { |v| options[:times6] = v }
  opts.on('-h', '--nh_address6 NHADDR', 'IPv6 NH address') { |v| options[:nh6] = v }
  opts.on('-s', '--source_address IPADDR', 'traffic source address') { |v| options[:source_add] = v }



end.parse!

puts options[:@local_add]
pp options
@remote_add = options[:remote_add] ||= '210.3.2.3'
@local_add = options[:local_add] ||= '210.3.2.6'
@local_as = options[:local_as] ||= 600
@times4 = options[:times4]
@times6 = options[:times6]
@source_add = options[:source_add] ||= '210.4.2.5'
nexthop6 = options[:nh6] ||= '2210:210:3:2::6'

neighbor = Neighbor.new \
  :version => 4,
  :my_as=> @local_as,
  :remote_addr => @remote_add,
  :local_addr => @local_add,
  :id=> '3.3.3.3',
  :holdtime=> 180

neighbor.capability_mbgp_ipv4_unicast
neighbor.capability_mbgp_ipv6_unicast
neighbor.capability :as4_byte

pa4 = Path_attribute.new(
  Origin.new(0),
  Next_hop.new(@local_add),
#  Local_pref.new(200),
  Communities.new(*("100:1 200:1 300:1 2938:22 324:3432 3344:343 4466:6436 5445:3454 3545:5677 5754:5754".split.map { |com| com.to_i})),
  As_path.new(*("790 90 80 2334 544 56 67 889 3111 777 8 879 0900 88 7654 3211 113 43434 666 343 4534 667 7688".split.map { |as| as.to_i}))
)
pp pa4


pa6 = Path_attribute.new(
    Origin.new(0),
    Communities.new(*("100:1 200:1 300:1 2938:22 324:3432 3344:343 4466:6436 5445:3454 3545:5677 5754:5754".split.map { |com| com.to_i})),
    As_path.new(*("790 90 80 2334 544 56 67 889 3111 777 8 879 0900 88 7654 3211 113 43434 666 343 4534 667 7688".split.map { |as| as.to_i}))
)


pp pa6

neighbor.start
@pack4 = 90
begin
  @nlri4 = IPAddr.new "20.0.0.0/28"
  senderv4 = File.open("senderv4", 'w')
  nlris = Nlri.new
    (1..@times4.to_i).each do |n|
#     senderv4.write("mz -c 2 -d 250msec -B %s -t udp dp=999 -A #{@source_add} \n" % (IPAddr.new(@nlri4 ^ n).succ))
     nlris << (@nlri4 ^ n)
     next unless (n % @pack4) == 0  or (n == @times4)
     senderv4.write("mz -c 2 -d 250msec -B %s -t udp dp=999 -A #{@source_add} \n" % (IPAddr.new(@nlri4 ^ n).succ))
     neighbor.send_message Update.new(pa4, nlris)

#     senderv4.write("mz -c 1 -B %s -t udp dp=999 -A #{@source_add} &\n" % (IPAddr.new(@nlri4 ^ n).succ))
#     senderv4.write("sleep 2\n") if (n % 500) == 0
      nlris = Nlri.new
  end
  senderv4.close()
end if @times4

begin
  senderv6 = File.open("senderv6", 'w')
  subnet = Fiber.new do
    address = IPAddr.new "5000:9999:8888:1::0/64"
    pack = 15
    prefixes = []
    (@times6).to_i.times do |n|
     senderv6.write("ping6 %s -c 1 -w 1 \n" % (IPAddr.new(address ^ n).succ))
#     senderv6.write("ping6 %s -c 1 -w 1 &\n" % (IPAddr.new(address ^ n).succ))
#     senderv6.write("sleep 2\n") if (n % 500) == 0
     prefixes << (address ^ n)
     next unless (n % pack) == 0
     Fiber.yield prefixes
     prefixes=[]
    end
    Fiber.yield prefixes unless prefixes.empty?
    nil
    senderv6.close()
end

while nets = subnet.resume
  neighbor.send_message Update.new pa6.replace(Mp_reach.new(:afi=>2, :safi=>1, :nexthop=> nexthop6, :nlris=> nets))
end
end if @times6


sleep(36000)


