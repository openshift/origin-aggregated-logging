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

module Protocol
	module HTTP2
		# Certain frames can have padding:
		# https://http2.github.io/http2-spec/#padding
		#
		# +---------------+
		# |Pad Length? (8)|
		# +---------------+-----------------------------------------------+
		# |                            Data (*)                         ...
		# +---------------------------------------------------------------+
		# |                           Padding (*)                       ...
		# +---------------------------------------------------------------+
		#
		module Padded
			def padded?
				flag_set?(PADDED)
			end
			
			def pack(data, padding_size: nil, maximum_size: nil)
				if padding_size
					set_flags(PADDED)
					
					buffer = String.new.b
					
					buffer << padding_size.chr
					buffer << data
					
					if padding_size > 1
						buffer << "\0" * (padding_size - 1)
					end
					
					super buffer
				else
					clear_flags(PADDED)
					
					super data
				end
			end
			
			def unpack
				if padded?
					padding_size = @payload[0].ord
					data_size = (@payload.bytesize - 1) - padding_size
					
					if data_size < 0
						raise ProtocolError, "Invalid padding length: #{padding_size}"
					end
					
					return @payload.byteslice(1, data_size)
				else
					return @payload
				end
			end
		end
	end
end
