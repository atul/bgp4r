#--
# Copyright 2012 Jean-Michel Esnault.
# All rights reserved.
# See LICENSE.txt for permissions.
#
#
# This file is part of BGP4R.
# 
# BGP4R is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# BGP4R is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with BGP4R.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'bgp/nlris/evpn'
require 'test/unit'

class TestEvpn < Test::Unit::TestCase
  
  include BGP
  
  def test_1
    ad = Auto_discovery.new
    assert_equal("011900000000000000000000000000000000000000000000000001", ad.to_shex)
    assert_equal("rd: 0:0, esi: 0:0:0:0:0:0:0:0:0:0, tag: 0, label: 0", ad.to_s)
    ad = Auto_discovery.new :rd=> Rd.new(1,1), :esi=>100, :tag=>10, :label=> Label.new(100) 
    assert_equal("01190000000100000001640000000000000000000000000a000641", ad.to_shex)
    assert_equal("rd: 1:1, esi: 100:0:0:0:0:0:0:0:0:0, tag: 10, label: 100", ad.to_s)
    ad = Auto_discovery.new :rd=> [1,1], :esi=> 100, :tag=>10, :label=>100
    assert_equal("01190000000100000001640000000000000000000000000a000641", ad.to_shex)
    assert_equal("rd: 1:1, esi: 100:0:0:0:0:0:0:0:0:0, tag: 10, label: 100", ad.to_s)
    ad = Auto_discovery.new :rd=> [1,1], :esi=> [1,2,3,4,5], :tag=>10, :label=>100
    assert_equal("01190000000100000001010203040500000000000000000a000641", ad.to_shex)
    assert_equal("rd: 1:1, esi: 1:2:3:4:5:0:0:0:0:0, tag: 10, label: 100", ad.to_s)
  end
  
  def test_2
    ad = Auto_discovery.new :rd=> [1,1], :esi=> [1,2,3,4,5], :tag=>10, :label=>100
    ad2 = Auto_discovery.new(ad.encode)
    assert_equal(ad.encode, ad2.encode)
  end

end  

class TestMacAdvertisement < Test::Unit::TestCase
  
  include BGP
  
  def test_1
    ma = Mac_advertisement.new
    assert_equal("022200000000000000000000000000000000000000000000040000000006000000000000", ma.to_shex)
    
    ma = Mac_advertisement.new :labels => [1,2]
    assert_equal([1,2], ma.labels.to_ary)
    assert_equal('0:0', ma.rd.to_s2)
    assert_equal(0, ma.tag)
    assert_equal("022800000000000000000000000000000000000000000000040000000006000000000000000010000021", ma.to_shex)

    ma = Mac_advertisement.new :labels => [100,200,300], :rd=> [200,200], :tag=> 100, :esi=> [1,2,3,4,5], :mac=>"01:02:03:04:05:06"
    assert_equal(2, ma.route_type)
    assert_equal([100,200,300], ma.labels.to_ary)
    assert_equal('200:200', ma.rd.to_s2)
    assert_equal(100, ma.tag)
    assert_equal("01:02:03:04:05:06", ma.mac.to_s)
    assert_equal("022b000000c8000000c80102030405000000000000000064040000000006010203040506000640000c800012c1", ma.to_shex)
    
    ma = Mac_advertisement.new :labels => [100,200,300], :rd=> [200,200], :tag=> 100, :esi=> [1,2,3,4,5], :mac=>"01:02:03:04:05:06", :ipaddr=>"192.168.0.1"
    assert_equal(2, ma.route_type)
    assert_equal([100,200,300], ma.labels.to_ary)
    assert_equal('200:200', ma.rd.to_s2)
    assert_equal(100, ma.tag)
    assert_equal("01:02:03:04:05:06", ma.mac.to_s)
    assert_equal("192.168.0.1", ma.ipaddr.to_s)
    assert_equal("022b000000c8000000c8010203040500000000000000006404c0a8000106010203040506000640000c800012c1", ma.to_shex)
    
    ma = Mac_advertisement.new :labels => [100,200,300], :rd=> [200,200], :tag=> 100, :esi=> [1]*10, :mac=>"01:02:03:04:05:06", :ipaddr=>"2012:1:2:3::0/65"
    assert_equal(2, ma.route_type)
    assert_equal([100,200,300], ma.labels.to_ary)
    assert_equal('200:200', ma.rd.to_s2)
    assert_equal(100, ma.tag)
    assert_equal("01:02:03:04:05:06", ma.mac.to_s)
    assert_equal("2012:1:2:3::", ma.ipaddr.to_s)
    assert_equal("0237000000c8000000c80101010101010101010100000064102012000100020003000000000000000006010203040506000640000c800012c1", ma.to_shex)
    
  end
  
  def test_2
    ma1 = Mac_advertisement.new :labels => [100,200,300], :rd=> [200,200], :tag=> 100, :esi=> [1]*10, :mac=>"01:02:03:04:05:06", :ipaddr=>"2012:1:2:3::0/65"
    ma2 = Mac_advertisement.new(ma1.encode)
    assert_equal(ma1.to_shex, ma2.to_shex)
    assert_equal("rd: 200:200, esi: 1:1:1:1:1:1:1:1:1:1, tag: 100, ipaddr: 2012:1:2:3::, mac: 01:02:03:04:05:06, labels: 100,200,300", ma1.to_s)
  end

end  

class TestInclusiveMcastEthernetTag < Test::Unit::TestCase
  
  include BGP
  
  def test_1
    imet = Inclusive_mcast_ethernet_tag.new
    assert_equal("031b000000000000000000000000000000000000000000000400000000", imet.to_shex)
    
    imet = Inclusive_mcast_ethernet_tag.new :ipaddr=> "192.168.1.1", :rd=>[200,300], :esi=>[2]*10, :tag=>1311
    assert_equal('200:300', imet.rd.to_s2)
    assert_equal(1311, imet.tag)
    assert_equal("031b000000c80000012c020202020202020202020000051f04c0a80101", imet.to_shex)
    
    imet = Inclusive_mcast_ethernet_tag.new :ipaddr=> "2012:11:13::1", :rd=>[200,300], :esi=>[2]*10, :tag=>1311
    assert_equal('200:300', imet.rd.to_s2)
    assert_equal(1311, imet.tag)
    assert_equal("0327000000c80000012c020202020202020202020000051f1020120011001300000000000000000001", imet.to_shex)
    
  end
  
  def test_2
    imet1 = Inclusive_mcast_ethernet_tag.new :ipaddr=> "2012:11:13::1", :rd=>[200,300], :esi=>[2]*10, :tag=>1311
    imet2 = Inclusive_mcast_ethernet_tag.new(imet1.encode)
    assert_equal(imet1.to_shex, imet2.to_shex)
    assert_equal("rd: 200:300, esi: 2:2:2:2:2:2:2:2:2:2, tag: 1311, ipaddr: 2012:11:13::1",imet1.to_s)
  end

end  

class TestEthernetSegment < Test::Unit::TestCase
  
  include BGP
  
  def test_1
    es = Ethernet_segment.new
    assert_equal("0412000000000000000000000000000000000000", es.to_shex)
    
    es = Ethernet_segment.new :rd=>[200,300], :esi=>[2]*10
    assert_equal('200:300', es.rd.to_s2)
    assert_equal("0412000000c80000012c02020202020202020202", es.to_shex)
    assert_equal("rd: 200:300, esi: 2:2:2:2:2:2:2:2:2:2", es.to_s)
        
  end
  
  def test_2
    es1 = Ethernet_segment.new :rd=>[200,300], :esi=>[2]*10
    es2 = Ethernet_segment.new(es1.encode)
    assert_equal(es1.to_shex, es2.to_shex)
  end

end  
