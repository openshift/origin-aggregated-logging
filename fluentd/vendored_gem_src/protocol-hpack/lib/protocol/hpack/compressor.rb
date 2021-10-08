# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# Copyrigh, 2013, by Ilya Grigorik.
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

require_relative 'context'
require_relative 'huffman'

module Protocol
	module HPACK
		# Predefined options set for Compressor
		# http://mew.org/~kazu/material/2014-hpack.pdf
		NAIVE = {index: :never, huffman: :never}
		LINEAR = {index: :all, huffman: :never}
		STATIC = {index: :static, huffman: :never}
		SHORTER = {index: :all, huffman: :never}
		NAIVE_HUFFMAN = {index: :never, huffman: :always}
		LINEAR_HUFFMAN = {index: :all, huffman: :always}
		STATIC_HUFFMAN = {index: :static, huffman: :always}
		SHORTER_HUFFMAN = {index: :all, huffman: :shorter}
		
		MODES = {
			naive: NAIVE,
			linear: LINEAR,
			static: STATIC,
			shorter: SHORTER,
			naive_huffman: NAIVE_HUFFMAN,
			linear_huffman: NAIVE_HUFFMAN,
			static_huffman: NAIVE_HUFFMAN,
			shorter_huffman: NAIVE_HUFFMAN,
		}
		
		# Responsible for encoding header key-value pairs using HPACK algorithm.
		class Compressor
			def initialize(buffer, context = Context.new, table_size_limit: nil)
				@buffer = buffer
				@context = context
				
				@table_size_limit = table_size_limit
			end
			
			attr :table_size_limit
			
			attr :buffer
			attr :context
			attr :offset
			
			def write_byte(byte)
				@buffer << byte.chr
			end
			
			def write_bytes(bytes)
				@buffer << bytes
			end
			
			# Encodes provided value via integer representation.
			# - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#section-5.1
			#
			#  If I < 2^N - 1, encode I on N bits
			#  Else
			#      encode 2^N - 1 on N bits
			#      I = I - (2^N - 1)
			#      While I >= 128
			#           Encode (I % 128 + 128) on 8 bits
			#           I = I / 128
			#      encode (I) on 8 bits
			#
			# @param value [Integer] value to encode
			# @param bits [Integer] number of available bits
			# @return [String] binary string
			def write_integer(value, bits)
				limit = 2**bits - 1
				
				return write_bytes([value].pack('C')) if value < limit
				
				bytes = []
				bytes.push(limit) unless bits.zero?
				
				value -= limit
				while value >= 128
					bytes.push((value % 128) + 128)
					value /= 128
				end
				
				bytes.push(value)
				
				write_bytes(bytes.pack('C*'))
			end
			
			def huffman
				@context.huffman
			end
			
			# Encodes provided value via string literal representation.
			# - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#section-5.2
			#
			# * The string length, defined as the number of bytes needed to store
			#   its UTF-8 representation, is represented as an integer with a seven
			#   bits prefix. If the string length is strictly less than 127, it is
			#   represented as one byte.
			# * If the bit 7 of the first byte is 1, the string value is represented
			#   as a list of Huffman encoded octets
			#   (padded with bit 1's until next octet boundary).
			# * If the bit 7 of the first byte is 0, the string value is
			#   represented as a list of UTF-8 encoded octets.
			#
			# +@options [:huffman]+ controls whether to use Huffman encoding:
			#  :never   Do not use Huffman encoding
			#  :always  Always use Huffman encoding
			#  :shorter Use Huffman when the result is strictly shorter
			#
			# @param string [String]
			# @return [String] binary string
			def write_string(string, huffman = self.huffman)
				if huffman != :never
					encoded = Huffman.new.encode(string)
					
					if huffman == :shorter and encoded.bytesize >= string.bytesize
						encoded = nil
					end
				end
				
				if encoded
					first = @buffer.bytesize
					
					write_integer(encoded.bytesize, 7)
					write_bytes(encoded.b)
					
					@buffer.setbyte(first, @buffer.getbyte(first).ord | 0x80)
				else
					write_integer(string.bytesize, 7)
					write_bytes(string.b)
				end
			end

			# Encodes header command with appropriate header representation.
			#
			# @param h [Hash] header command
			# @param buffer [String]
			# @return [Buffer]
			def write_header(command)
				representation = HEADER_REPRESENTATION[command[:type]]
				
				first = @buffer.bytesize
				
				case command[:type]
				when :indexed
					write_integer(command[:name] + 1, representation[:prefix])
				when :change_table_size
					write_integer(command[:value], representation[:prefix])
				else
					if command[:name].is_a? Integer
						write_integer(command[:name] + 1, representation[:prefix])
					else
						write_integer(0, representation[:prefix])
						write_string(command[:name])
					end
					
					write_string(command[:value])
				end

				# set header representation pattern on first byte
				@buffer.setbyte(first, @buffer.getbyte(first) | representation[:pattern])
			end

			# Encodes provided list of HTTP headers.
			#
			# @param headers [Array] +[[name, value], ...]+
			# @return [Buffer]
			def encode(headers, table_size = @table_size_limit)
				if table_size and table_size != @context.table_size
					command = @context.change_table_size(table_size)
					
					write_header(command)
				end
				
				commands = @context.encode(headers)
				
				commands.each do |command|
					write_header(command)
				end
				
				return @buffer
			end
		end
	end
end
