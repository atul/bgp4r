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

require 'bgp/common'
require 'bgp/nlris/label'
require 'bgp/nlris/rd'
require 'bgp/IEs/mac'
  
module BGP
    
  module Evpn_Base

    AUTO_DISCOVERY         = 1
    MAC_ADVERTISEMENT      = 2
    INCLUSIVE_MCAST_ROUTE  = 3
    ETHERNET_SEGMENT_ROUTE = 4
    
    def encode(t,v)
      [t,v.size,v].pack('CCa*')
    end
    
    def parse(s)
      t,l,v = s.unpack('CCa*')
      v[0,l]
    end

    def rd=(arg)
      @rd = arg.is_a?(Rd) ? arg : Rd.new(*arg)
    end

    def tag=(arg)
      @tag=arg
    end

    def esi=(*arg)
      arg.flatten!
      @esi = (arg + [0]*10)[0..9]
    end

    attr_reader :rd, :esi, :tag

    private 
    
    def esi_to_s
      esi.join(':')
    end

  end
      
  class Auto_discovery
    
    include Evpn_Base
    
    def initialize(*args)

      @rd = Rd.new
      @esi=[0]*10
      @tag=0
      @label=Label.new(0)

      case args[0]
      when Hash
        self.rd= args[0][:rd]
        self.tag=args[0][:tag]
        self.esi=args[0][:esi]
        self.label=args[0][:label]
      when String
        parse(args[0])
      end
    end
    
    def route_type
      AUTO_DISCOVERY
    end
    
    def label=(arg)
      @label = arg.is_a?(Label) ? arg : Label.new(arg)
    end

    attr_reader :label
    
    def to_s
      "rd: #{rd.to_s2}, esi: #{esi_to_s}, tag: #{tag}, label: #{label.label}"
    end
    
    def parse(_s)
      s = super(_s)
      @rd = Rd.new(s.slice!(0,8).is_packed)
      @esi= s.slice!(0,10).unpack('C*')
      @tag= s.slice!(0,4).unpack('N')
      @label=Label.new(s.slice!(0,3).is_packed)
    end
    
    def encode
      super route_type, [@rd.encode,@esi,@tag, @label.encode].flatten.pack('a*C10Na*')
    end

  end
    
  class Mac_advertisement
    
    include Evpn_Base
    
    attr_reader :labels, :mac, :ipaddr
    
    def initialize(*args)

      @rd = Rd.new
      @esi=[0]*10
      @tag=0
      @mac = Mac.new
      @ipaddr = IPAddr.new("0.0.0.0/0")
      @labels=Label_stack.new

      case args[0]
      when Hash
        self.rd= args[0][:rd]         if args[0][:rd]
        self.esi=args[0][:esi]        if args[0][:esi]
        self.tag=args[0][:tag]        if args[0][:tag]
        self.mac=args[0][:mac]        if args[0][:mac]
        self.ipaddr=args[0][:ipaddr]  if args[0][:ipaddr]
        self.labels=args[0][:labels]  if args[0][:labels]

      when String
        parse(args[0])
      end
    end    
    
    def ipaddr=(arg)
      @ipaddr = arg.is_a?(IPAddr) ? arg : IPAddr.new(arg)
    end
    
    def mac=(arg)
      @mac = arg.is_a?(Mac) ? arg : Mac.new(arg)
    end

    def labels=(arg)
      @labels = arg.is_a?(Label_stack) ? arg : Label_stack.new(*arg)
    end
    
    def route_type
      MAC_ADVERTISEMENT
    end
    
    def encode
      ipaddr = @ipaddr.hton
      ipaddr_size = ipaddr.size
      mac = @mac.encode
      mac_size = mac.size
      s=[]
      s << [@rd.encode,@esi,@tag].flatten.pack('a*C10N')
      s << [ipaddr_size, ipaddr, mac_size, mac].pack('Ca*Ca*')
      s << @labels.encode
      super route_type, s.join
    end
    
    def parse(_s)
      s = super(_s)
      @rd = Rd.new(s.slice!(0,8).is_packed)
      @esi= s.slice!(0,10).unpack('C*')
      @tag= s.slice!(0,4).unpack('N')
      l = s.slice!(0,1).unpack('C')[0]
      @ipaddr = IPAddr.new(IPAddr.ntop(s.slice!(0,l)))
      l = s.slice!(0,1).unpack('C')[0]
      @mac = Mac.new(s.slice!(0,l))
      @labels = Label_stack.new_ntop(s)
    end
    
    def to_s
      "rd: #{rd.to_s2}, esi: #{esi_to_s}, tag: #{tag}, ipaddr: #{ipaddr}, mac: #{mac}, labels: #{labels.to_ary.join("," )}"
    end
      
  end
  
  class Inclusive_mcast_ethernet_tag
    
      include Evpn_Base
    
      attr_reader :ipaddr
    
      def initialize(*args)

        @rd = Rd.new
        @esi=[0]*10
        @tag=0
        @mac = Mac.new
        @ipaddr = IPAddr.new("0.0.0.0/0")
        @labels=Label_stack.new

        case args[0]
        when Hash
          self.rd= args[0][:rd]         if args[0][:rd]
          self.esi=args[0][:esi]        if args[0][:esi]
          self.tag=args[0][:tag]        if args[0][:tag]
          self.ipaddr=args[0][:ipaddr]  if args[0][:ipaddr]

        when String
          parse(args[0])
        end
      end    
    
      def ipaddr=(arg)
        @ipaddr = arg.is_a?(IPAddr) ? arg : IPAddr.new(arg)
      end
    
      def mac=(arg)
        @mac = arg.is_a?(Mac) ? arg : Mac.new(arg)
      end

      def labels=(arg)
        @labels = arg.is_a?(Label_stack) ? arg : Label_stack.new(*arg)
      end
    
      def route_type
        INCLUSIVE_MCAST_ROUTE
      end
    
      def encode
        ipaddr = @ipaddr.hton
        ipaddr_size = ipaddr.size
        mac = @mac.encode
        mac_size = mac.size
        s=[]
        s << [@rd.encode,@esi,@tag].flatten.pack('a*C10N')
        s << [ipaddr_size, ipaddr].pack('Ca*')
        super route_type, s.join
      end
    
      def parse(_s)
        s = super(_s)
        @rd = Rd.new(s.slice!(0,8).is_packed)
        @esi= s.slice!(0,10).unpack('C*')
        @tag= s.slice!(0,4).unpack('N')
        l = s.slice!(0,1).unpack('C')[0]
        @ipaddr = IPAddr.new(IPAddr.ntop(s.slice!(0,l)))
      end
      
      def to_s
        "rd: #{rd.to_s2}, esi: #{esi_to_s}, tag: #{tag}, ipaddr: #{ipaddr}"
      end
      
    end
    
    class Ethernet_segment
    
      include Evpn_Base
        
      def initialize(*args)

        @rd = Rd.new
        @esi=[0]*10

        case args[0]
        when Hash
          self.rd= args[0][:rd]         if args[0][:rd]
          self.esi=args[0][:esi]        if args[0][:esi]

        when String
          parse(args[0])
        end
      end    
    
      def route_type
        ETHERNET_SEGMENT_ROUTE
      end
    
      def encode
        super route_type, [@rd.encode,@esi].flatten.pack('a*C10')
      end
      
      def to_s
        "rd: #{rd.to_s2}, esi: #{esi_to_s}"
      end
      
    
      def parse(_s)
        s = super(_s)
        @rd = Rd.new(s.slice!(0,8).is_packed)
        @esi= s.slice!(0,10).unpack('C*')
      end
      
    end
  
end
