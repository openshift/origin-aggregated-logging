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

require 'zlib'

require_relative 'deflate'

module Protocol
	module HTTP
		module Body
			class Inflate < ZStream
				def self.for(body, encoding = GZIP)
					self.new(body, Zlib::Inflate.new(encoding))
				end
				
				def read
					return if @stream.finished?
					
					# The stream might have been closed while waiting for the chunk to come in.
					if chunk = super
						@input_length += chunk.bytesize
						
						# It's possible this triggers the stream to finish.
						chunk = @stream.inflate(chunk)
						
						@output_length += chunk.bytesize
					elsif !@stream.closed?
						chunk = @stream.finish
						
						@output_length += chunk.bytesize
					end
					
					if chunk.empty? and @stream.finished?
						return nil
					end
					
					return chunk
				end
			end
		end
	end
end