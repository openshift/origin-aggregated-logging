# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'protocol/http/error'

module Protocol
	module HTTP2
		# Status codes as defined by <https://tools.ietf.org/html/rfc7540#section-7>.
		class Error < HTTP::Error
			# The associated condition is not a result of an error.  For example, a GOAWAY might include this code to indicate graceful shutdown of a connection.
			NO_ERROR = 0x0
			
			# The endpoint detected an unspecific protocol error.  This error is for use when a more specific error code is not available.
			PROTOCOL_ERROR = 0x1
			
			# The endpoint encountered an unexpected internal error.
			INTERNAL_ERROR = 0x2
			
			# The endpoint detected that its peer violated the flow-control protocol.
			FLOW_CONTROL_ERROR = 0x3
			
			# The endpoint sent a SETTINGS frame but did not receive a response in a timely manner.
			SETTINGS_TIMEOUT = 0x4
			
			# The endpoint received a frame after a stream was half-closed.
			STREAM_CLOSED = 0x5
			
			# The endpoint received a frame with an invalid size.
			FRAME_SIZE_ERROR = 0x6
			
			# The endpoint refused the stream prior to performing any application processing.
			REFUSED_STREAM = 0x7
			
			# Used by the endpoint to indicate that the stream is no longer needed.
			CANCEL = 0x8
			
			# The endpoint is unable to maintain the header compression context for the connection.
			COMPRESSION_ERROR = 0x9
			
			# The connection established in response to a CONNECT request was reset or abnormally closed.
			CONNECT_ERROR = 0xA
			
			# The endpoint detected that its peer is exhibiting a behavior that might be generating excessive load.
			ENHANCE_YOUR_CALM = 0xB
			
			# The underlying transport has properties that do not meet minimum security requirements.
			INADEQUATE_SECURITY = 0xC
			
			# The endpoint requires that HTTP/1.1 be used instead of HTTP/2.
			HTTP_1_1_REQUIRED = 0xD
		end
		
		# Raised if connection header is missing or invalid indicating that
		# this is an invalid HTTP 2.0 request - no frames are emitted and the
		# connection must be aborted.
		class HandshakeError < Error
		end

		# Raised by stream or connection handlers, results in GOAWAY frame
		# which signals termination of the current connection. You *cannot*
		# recover from this exception, or any exceptions subclassed from it.
		class ProtocolError < Error
			def initialize(message, code = PROTOCOL_ERROR)
				super(message)
				
				@code = code
			end
			
			attr :code
		end
		
		class StreamError < ProtocolError
		end
		
		class StreamClosed < StreamError
			def initialize(message)
				super message, STREAM_CLOSED
			end
		end
		
		class HeaderError < StreamClosed
			def initialize(message)
				super(message)
			end
		end
		
		class GoawayError < ProtocolError
		end
		
		# When the frame payload does not match expectations.
		class FrameSizeError < ProtocolError
			def initialize(message)
				super message, FRAME_SIZE_ERROR
			end
		end
		
		# Raised on invalid flow control frame or command.
		class FlowControlError < ProtocolError
			def initialize(message)
				super message, FLOW_CONTROL_ERROR
			end
		end
	end
end
