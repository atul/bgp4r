module BGP

  class Mac

    attr_reader :mac

    def initialize(arg=[0]*6)
      case arg
      when String
        case arg.size
        when 6
          parse(arg)
        when 14
          parse [arg.split('.').join].pack('H*')
        else
          @mac = arg.split(/[-:]/).collect { |n| n.to_i(16) }
        end
      when Array
        if arg.size==6 and 
          arg[0].is_a?(Integer) and 
          arg[1].is_a?(Integer) and
          arg[2].is_a?(Integer) and
          arg[3].is_a?(Integer) and
          arg[4].is_a?(Integer) and
          arg[5].is_a?(Integer)
          @mac = arg
        end
      when self.class
        parse arg.encode
      end

      raise ArgumentError, "Argument error: #{self.class} #{arg.inspect}" unless @mac

    end

    def equals?(obj)
      case obj
      when Address
        encode == obj.encode
      else
        encode == self.class.new(obj).encode
      end 
    end

    def to_s(delim=":")
      case delim
      when ':'
        (format (["%02x"]*6).join(delim), *@mac)
      when '.'
        (format (["%04x"]*3).join(delim), *(@mac.pack('C6').unpack('n3')))
      end
    end

    def encode
      @mac.pack('C*')
    end
    
    def to_hash
      to_s
    end

    private

    def parse(s)
      @mac = s.unpack('C6')
    end
  end

end