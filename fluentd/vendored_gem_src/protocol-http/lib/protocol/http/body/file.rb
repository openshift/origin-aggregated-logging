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

require_relative 'readable'
require 'async/io/stream'

module Protocol
	module HTTP
		module Body
			class File < Readable
				BLOCK_SIZE = Async::IO::BLOCK_SIZE
				MODE = ::File::RDONLY | ::File::BINARY
				
				def self.open(path, *arguments, **options)
					self.new(::File.open(path, MODE), *arguments, **options)
				end
				
				def initialize(file, range = nil, size: file.size, block_size: BLOCK_SIZE)
					@file = file
					
					@block_size = block_size
					
					if range
						@file.seek(range.min)
						@offset = range.min
						@length = @remaining = range.size
					else
						@offset = 0
						@length = @remaining = size
					end
				end
				
				def close(error = nil)
					@file.close
					@remaining = 0
					
					super
				end
				
				attr :file
				
				attr :offset
				attr :length
				
				def empty?
					@remaining == 0
				end
				
				def ready?
					true
				end
				
				def rewind
					@file.seek(@offset)
				end
				
				def read
					if @remaining > 0
						amount = [@remaining, @block_size].min
						
						if chunk = @file.read(amount)
							@remaining -= chunk.bytesize
							
							return chunk
						end
					end
				end
				
				def join
					return "" if @remaining == 0
					
					buffer = @file.read(@remaining)
					
					@remaining = 0
					
					return buffer
				end
				
				def inspect
					"\#<#{self.class} file=#{@file.inspect} offset=#{@offset} remaining=#{@remaining}>"
				end
			end
		end
	end
end
