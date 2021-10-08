# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# Copyright, 2013, by Ilya Grigorik.
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

module Protocol
	module HTTP2
		# DATA frames convey arbitrary, variable-length sequences of octets associated with a stream. One or more DATA frames are used, for instance, to carry HTTP request or response payloads.
		# 
		# DATA frames MAY also contain padding. Padding can be added to DATA frames to obscure the size of messages.
		# 
		# +---------------+
		# |Pad Length? (8)|
		# +---------------+-----------------------------------------------+
		# |                            Data (*)                         ...
		# +---------------------------------------------------------------+
		# |                           Padding (*)                       ...
		# +---------------------------------------------------------------+
		#
		class DataFrame < Frame
			include Padded
			
			TYPE = 0x0
			
			def end_stream?
				flag_set?(END_STREAM)
			end
			
			def pack(data, *arguments, **options)
				if data
					super
				else
					@length = 0
					set_flags(END_STREAM)
				end
			end
			
			def apply(connection)
				connection.receive_data(self)
			end
			
			def inspect
				"\#<#{self.class} stream_id=#{@stream_id} flags=#{@flags} #{@length}b>"
			end
		end
	end
end
