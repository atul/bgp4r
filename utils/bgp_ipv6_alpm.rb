require 'bgp4r'

include BGP

Log.create
Log.level=Logger::INFO

neighbor = Neighbor.new \
:version=> 4,
:my_as=> 100,
:remote_addr => '169.253.253.102',
:id=> '20.20.20.20',
:holdtime=> 180

neighbor.capability_mbgp_ipv4_unicast
neighbor.capability_mbgp_ipv6_unicast

nexthop='fe80::20c:29ff:fcab:13b'

pa = Path_attribute.new(
    Origin.new(0),
    Multi_exit_disc.new(0),
    As_path.new(),
)

# 22 routes, 5 routes per update
subnet = Fiber.new do
  ipaddr = IPAddr.new "2014:13:11::1/65"
  pack=5
  prefixes=[]
  22.times do |i|
    prefixes << (ipaddr ^ i)
    next unless (i%pack)==0
    Fiber.yield prefixes
    prefixes=[]
  end
  Fiber.yield prefixes unless prefixes.empty?
  nil
end

neighbor.start

while nets = subnet.resume
  neighbor.send_message Update.new pa.replace(Mp_reach.new(:afi=>2, :safi=>1, :nexthop=> nexthop, :nlris=> nets))
end

sleep(300)
