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

require_relative 'connection'

module Protocol
	module HTTP2
		class Server < Connection
			def initialize(framer)
				super(framer, 2)
			end
			
			def local_stream_id?(id)
				id.even?
			end
			
			def remote_stream_id?(id)
				id.odd?
			end
			
			def valid_remote_stream_id?(stream_id)
				stream_id.odd?
			end
			
			def read_connection_preface(settings = [])
				if @state == :new
					@framer.read_connection_preface
					
					send_settings(settings)
					
					read_frame do |frame|
						raise ProtocolError, "First frame must be #{SettingsFrame}, but got #{frame.class}" unless frame.is_a? SettingsFrame
					end
				else
					raise ProtocolError, "Cannot send connection preface in state #{@state}"
				end
			end
			
			def accept_push_promise_stream(stream_id, &block)
				raise ProtocolError, "Cannot accept push promises on server!"
			end
			
			def enable_push?
				@remote_settings.enable_push?
			end
		end
	end
end
