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
		VALID_WEIGHT = (1..256)
		
		# Stream Dependency:  A 31-bit stream identifier for the stream that
		# this stream depends on (see Section 5.3).  This field is only
		# present if the PRIORITY flag is set.
		class Priority < Struct.new(:exclusive, :stream_dependency, :weight)
			FORMAT = "NC".freeze
			EXCLUSIVE = 1 << 31
			
			# All streams are initially assigned a non-exclusive dependency on stream 0x0.  Pushed streams (Section 8.2) initially depend on their associated stream.  In both cases, streams are assigned a default weight of 16.
			def self.default(stream_dependency = 0, weight = 16)
				self.new(false, stream_dependency, weight)
			end
			
			def self.unpack(data)
				stream_dependency, weight = data.unpack(FORMAT)
				
				# Weight:  An unsigned 8-bit integer representing a priority weight for the stream (see Section 5.3).  Add one to the value to obtain a weight between 1 and 256.  This field is only present if the PRIORITY flag is set.
				return self.new(stream_dependency & EXCLUSIVE != 0, stream_dependency & ~EXCLUSIVE, weight + 1)
			end
			
			def pack
				if exclusive
					stream_dependency = self.stream_dependency | EXCLUSIVE
				else
					stream_dependency = self.stream_dependency
				end
				
				return [stream_dependency, self.weight - 1].pack(FORMAT)
			end
			
			def weight= value
				if VALID_WEIGHT.include?(value)
					super
				else
					raise ArgumentError, "Weight #{value} must be between 1-256!"
				end
			end
		end
		
		# The PRIORITY frame specifies the sender-advised priority of a stream. It can be sent in any stream state, including idle or closed streams.
		#
		# +-+-------------------------------------------------------------+
		# |E|                  Stream Dependency (31)                     |
		# +-+-------------+-----------------------------------------------+
		# |   Weight (8)  |
		# +-+-------------+
		#
		class PriorityFrame < Frame
			TYPE = 0x2
			
			def priority
				Priority.unpack(@payload)
			end
			
			def pack priority
				super priority.pack
			end
			
			def unpack
				Priority.unpack(super)
			end
			
			def apply(connection)
				connection.receive_priority(self)
			end
			
			def read_payload(stream)
				super
				
				if @length != 5
					raise FrameSizeError, "Invalid frame length"
				end
			end
		end
	end
end
