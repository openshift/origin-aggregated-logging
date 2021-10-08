# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'frame'

module Protocol
	module HTTP2
		ACKNOWLEDGEMENT = 0x1
		
		module Acknowledgement
			def acknowledgement?
				flag_set?(ACKNOWLEDGEMENT)
			end
			
			def acknowledge
				frame = self.class.new
				
				frame.length = 0
				frame.set_flags(ACKNOWLEDGEMENT)
				
				return frame
			end
		end
		
		# The PING frame is a mechanism for measuring a minimal round-trip time from the sender, as well as determining whether an idle connection is still functional. PING frames can be sent from any endpoint.
		#
		# +---------------------------------------------------------------+
		# |                                                               |
		# |                      Opaque Data (64)                         |
		# |                                                               |
		# +---------------------------------------------------------------+
		#
		class PingFrame < Frame
			TYPE = 0x6
			
			include Acknowledgement
			
			def connection?
				true
			end
			
			def apply(connection)
				connection.receive_ping(self)
			end
			
			def acknowledge
				frame = super
				
				frame.pack self.unpack
				
				return frame
			end
			
			def read_payload(stream)
				super
				
				if @length != 8
					raise FrameSizeError, "Invalid frame length: #{@length} != 8!"
				end
			end
		end
	end
end
