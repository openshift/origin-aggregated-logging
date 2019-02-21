module SyslogProtocol
  class Logger
    def initialize(hostname, tag, facility)
      @packet = Packet.new
      @packet.hostname = hostname
      @packet.tag      = tag
      @packet.facility = facility
    end
    
    SEVERITIES.each do |k,v|
      define_method(k) do |content|
        raise ArgumentError.new("Message may not be omitted") unless content and content.length > 0

        p = @packet.dup
        p.severity = k
        p.content = content
        p.assemble
      end
    end
  end
end
