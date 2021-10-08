# frozen_string_literal: true

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

require 'protocol/http/body/readable'

module Protocol
	module HTTP1
		module Body
			class Remainder < HTTP::Body::Readable
				BLOCK_SIZE = 1024 * 64
				
				# block_size may be removed in the future. It is better managed by stream.
				def initialize(stream)
					@stream = stream
				end
				
				def empty?
					@stream.eof? or @stream.closed?
				end
				
				def close(error = nil)
					# We can't really do anything in this case except close the connection.
					@stream.close
					
					super
				end
				
				# TODO this is a bit less efficient in order to maintain compatibility with `IO`.
				def read
					@stream.readpartial(BLOCK_SIZE)
				rescue EOFError
					return nil
				end
				
				def call(stream)
					self.each do |chunk|
						stream.write(chunk)
					end
					
					stream.flush
				end
				
				def join
					@stream.read
				end
				
				def inspect
					"\#<#{self.class} #{@stream.closed? ? 'closed' : 'open'}>"
				end
			end
		end
	end
end
