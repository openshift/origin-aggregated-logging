require 'time'

module SyslogProtocol
  
  def self.parse(msg, origin=nil)
    packet = Packet.new
    original_msg = msg.dup
    pri = parse_pri(msg)
    if pri and (pri = pri.to_i).is_a? Integer and (0..191).include?(pri)
      packet.pri = pri
    else
      # If there isn't a valid PRI, treat the entire message as content
      packet.pri = 13
      packet.time = Time.now
      packet.hostname = origin || 'unknown'
      packet.content = original_msg
      return packet
    end
    time = parse_time(msg)
    if time
      packet.time = Time.parse(time)
    else
      packet.time = Time.now
    end
    hostname = parse_hostname(msg)
    packet.hostname = hostname || origin
    if m = msg.match(/^(\w+)(: | )(.*)$/)
      packet.tag = m[1]
      packet.content = m[3]
    else
      packet.tag = 'unknown'
      packet.content = msg
    end
    packet
  end
  
  private
  
  def self.parse_pri(msg)
    pri = msg.slice!(/<(\d\d?\d?)>/)
    pri = pri.slice(/\d\d?\d?/) if pri
    if !pri or (pri =~ /^0/ and pri !~ /^0$/)
      return nil
    else
      return pri
    end
  end
  
  def self.parse_time(msg)
    msg.slice!(/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s(\s|[1-9])\d\s\d\d:\d\d:\d\d\s/)
  end
  
  def self.parse_hostname(msg)
    msg.slice!(/^[\x21-\x7E]+\s/).rstrip
  end
  
end