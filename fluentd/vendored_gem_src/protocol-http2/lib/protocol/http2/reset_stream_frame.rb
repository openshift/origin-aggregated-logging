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
		NO_ERROR = 0
		PROTOCOL_ERROR = 1
		INTERNAL_ERROR = 2
		FLOW_CONTROL_ERROR = 3
		TIMEOUT = 4
		STREAM_CLOSED = 5
		FRAME_SIZE_ERROR = 6
		REFUSED_STREAM = 7
		CANCEL = 8
		COMPRESSION_ERROR = 9
		CONNECT_ERROR = 10
		ENHANCE_YOUR_CALM = 11
		INADEQUATE_SECURITY = 12
		HTTP_1_1_REQUIRED = 13
		
		# The RST_STREAM frame allows for immediate termination of a stream. RST_STREAM is sent to request cancellation of a stream or to indicate that an error condition has occurred.
		#
		# +---------------------------------------------------------------+
		# |                        Error Code (32)                        |
		# +---------------------------------------------------------------+
		#
		class ResetStreamFrame < Frame
			TYPE = 0x3
			FORMAT = "N".freeze
			
			def unpack
				@payload.unpack1(FORMAT)
			end
			
			def pack(error_code = NO_ERROR)
				@payload = [error_code].pack(FORMAT)
				@length = @payload.bytesize
			end
			
			def apply(connection)
				connection.receive_reset_stream(self)
			end
			
			def read_payload(stream)
				super
				
				if @length != 4
					raise FrameSizeError, "Invalid frame length"
				end
			end
		end
	end
end
