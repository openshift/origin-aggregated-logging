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
		# The GOAWAY frame is used to initiate shutdown of a connection or to signal serious error conditions. GOAWAY allows an endpoint to gracefully stop accepting new streams while still finishing processing of previously established streams. This enables administrative actions, like server maintenance.
		#
		# +-+-------------------------------------------------------------+
		# |R|                  Last-Stream-ID (31)                        |
		# +-+-------------------------------------------------------------+
		# |                      Error Code (32)                          |
		# +---------------------------------------------------------------+
		# |                  Additional Debug Data (*)                    |
		# +---------------------------------------------------------------+
		#
		class GoawayFrame < Frame
			TYPE = 0x7
			FORMAT = "NN"
			
			def connection?
				true
			end
			
			def unpack
				data = super
				
				last_stream_id, error_code = data.unpack(FORMAT)
				
				return last_stream_id, error_code, data.slice(8, data.bytesize-8)
			end
			
			def pack(last_stream_id, error_code, data)
				super [last_stream_id, error_code].pack(FORMAT) + data
			end
			
			def apply(connection)
				connection.receive_goaway(self)
			end
		end
	end
end
