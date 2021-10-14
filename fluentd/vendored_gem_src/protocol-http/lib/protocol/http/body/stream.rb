# frozen_string_literal: true

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

module Protocol
	module HTTP
		module Body
			# The input stream is an IO-like object which contains the raw HTTP POST data. When applicable, its external encoding must be “ASCII-8BIT” and it must be opened in binary mode, for Ruby 1.9 compatibility. The input stream must respond to gets, each, read and rewind.
			class Stream
				def initialize(input, output)
					@input = input
					@output = output
					
					# Will hold remaining data in `#read`.
					@buffer = nil
					@closed = false
				end
				
				attr :input
				attr :output
				
				# rack.hijack_io must respond to:
				# read, write, read_nonblock, write_nonblock, flush, close, close_read, close_write, closed?
				
				# read behaves like IO#read. Its signature is read([length, [buffer]]). If given, length must be a non-negative Integer (>= 0) or nil, and buffer must be a String and may not be nil. If length is given and not nil, then this method reads at most length bytes from the input stream. If length is not given or nil, then this method reads all data until EOF. When EOF is reached, this method returns nil if length is given and not nil, or “” if length is not given or is nil. If buffer is given, then the read data will be placed into buffer instead of a newly created String object.
				# @param length [Integer] the amount of data to read
				# @param buffer [String] the buffer which will receive the data
				# @return a buffer containing the data
				def read(length = nil, buffer = nil)
					buffer ||= Async::IO::Buffer.new
					buffer.clear
					
					until buffer.bytesize == length
						@buffer = read_next if @buffer.nil?
						break if @buffer.nil?
						
						remaining_length = length - buffer.bytesize if length
						
						if remaining_length && remaining_length < @buffer.bytesize
							# We know that we are not going to reuse the original buffer.
							# But byteslice will generate a hidden copy. So let's freeze it first:
							@buffer.freeze
							
							buffer << @buffer.byteslice(0, remaining_length)
							@buffer = @buffer.byteslice(remaining_length, @buffer.bytesize)
						else
							buffer << @buffer
							@buffer = nil
						end
					end
					
					return nil if buffer.empty? && length && length > 0
					
					return buffer
				end
				
				def read_nonblock(length, buffer = nil)
					@buffer ||= read_next
					chunk = nil
					
					if @buffer.bytesize > length
						chunk = @buffer.byteslice(0, length)
						@buffer = @buffer.byteslice(length, @buffer.bytesize)
					else
						chunk = @buffer
						@buffer = nil
					end
					
					if buffer
						buffer.replace(chunk)
					else
						buffer = chunk
					end
					
					return buffer
				end
				
				def write(buffer)
					@output.write(buffer)
				end
				
				alias write_nonblock write
				
				def flush
				end
				
				def close_read
					@input&.close
				end
				
				# close must never be called on the input stream. huh?
				def close_write
					@output&.close
				end
				
				# Close the input and output bodies.
				def close
					self.close_read
					self.close_write
				ensure
					@closed = true
				end
				
				# Whether the stream has been closed.
				def closed?
					@closed
				end
				
				# Whether there are any output chunks remaining?
				def empty?
					@output.empty?
				end
				
				private
				
				def read_next
					if chunk = @input&.read
						return chunk
					else
						@input = nil
						return nil
					end
				end
			end
		end
	end
end
