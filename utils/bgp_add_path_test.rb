require 'bgp4r'
include BGP

def create_fiber(base_prefix, path_id, nprefix=5, npack=1)
  fiber = Fiber.new do
    ipaddr = IPAddr.new(base_prefix)
    nlris = Nlri.new
    nprefix.times do |i|
      nlris  << [path_id, (ipaddr ^ i)]
      next unless (i%npack)==0
      Fiber.yield nlris
      nlris = Nlri.new
    end
    Fiber.yield nlris unless nlris.empty?
    nil
  end
  fiber
end

nexthop4='210.3.2.6'

pa = Path_attribute.new(
    Next_hop.new(nexthop4),
    Origin.new(0),
    As_path.new(200),
    Local_pref.new(100),
)

routes_ = []
10.times do |i|
  routes_[i] =(create_fiber("26.26.0.0/26",100 + i))
end


Log.create
Log.level=Logger::DEBUG

n = Neighbor.new :my_as=> 300, :remote_addr => '210.3.2.3', :id=> '3.3.3.3'

n.capability_mbgp_ipv4_unicast
n.capability_four_byte_as
n.add_cap OPT_PARM::CAP::Add_path.new( :send_and_receive, 1, 1)
n.start

routes_.each do |i|
  while nlris = i.resume
    n.send_message Update.new pa, nlris
  end
end

sleep(3000)
