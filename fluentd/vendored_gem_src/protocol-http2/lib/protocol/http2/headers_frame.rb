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
require_relative 'padded'
require_relative 'continuation_frame'
require_relative 'priority_frame'

module Protocol
	module HTTP2
		# The HEADERS frame is used to open a stream, and additionally carries a header block fragment. HEADERS frames can be sent on a stream in the "idle", "reserved (local)", "open", or "half-closed (remote)" state.
		# 
		# +---------------+
		# |Pad Length? (8)|
		# +-+-------------+-----------------------------------------------+
		# |E|                 Stream Dependency? (31)                     |
		# +-+-------------+-----------------------------------------------+
		# |  Weight? (8)  |
		# +-+-------------+-----------------------------------------------+
		# |                   Header Block Fragment (*)                 ...
		# +---------------------------------------------------------------+
		# |                           Padding (*)                       ...
		# +---------------------------------------------------------------+
		#
		class HeadersFrame < Frame
			include Continued, Padded
			
			TYPE = 0x1
			
			def priority?
				flag_set?(PRIORITY)
			end
			
			def end_stream?
				flag_set?(END_STREAM)
			end
			
			def unpack
				data = super
				
				if priority?
					priority = Priority.unpack(data)
					data = data.byteslice(5, data.bytesize - 5)
				end
				
				return priority, data
			end
			
			def pack(priority, data, *arguments, **options)
				buffer = String.new.b
				
				if priority
					buffer << priority.pack
					set_flags(PRIORITY)
				else
					clear_flags(PRIORITY)
				end
				
				buffer << data
				
				super(buffer, *arguments, **options)
			end
			
			def apply(connection)
				connection.receive_headers(self)
			end
			
			def inspect
				"\#<#{self.class} stream_id=#{@stream_id} flags=#{@flags} #{@length}b>"
			end
		end
	end
end
