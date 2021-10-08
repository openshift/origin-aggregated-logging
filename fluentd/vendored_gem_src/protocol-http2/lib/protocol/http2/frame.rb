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

require_relative 'error'

module Protocol
	module HTTP2
		END_STREAM = 0x1
		END_HEADERS = 0x4
		PADDED = 0x8
		PRIORITY = 0x20
		
		MAXIMUM_ALLOWED_WINDOW_SIZE = 0x7FFFFFFF
		MINIMUM_ALLOWED_FRAME_SIZE = 0x4000
		MAXIMUM_ALLOWED_FRAME_SIZE = 0xFFFFFF
		
		class Frame
			include Comparable
			
			# Stream Identifier cannot be bigger than this:
			# https://http2.github.stream/http2-spec/#rfc.section.4.1
			VALID_STREAM_ID = 0..0x7fffffff
			
			# The absolute maximum bounds for the length field:
			VALID_LENGTH = 0..0xffffff
			
			# Used for generating 24-bit frame length:
			LENGTH_HISHIFT = 16
			LENGTH_LOMASK  = 0xFFFF
			
			# @param length [Integer] the length of the payload, or nil if the header has not been read yet.
			def initialize(stream_id = 0, flags = 0, type = self.class::TYPE, length = nil, payload = nil)
				@length = length
				@type = type
				@flags = flags
				@stream_id = stream_id
				@payload = payload
			end
			
			def valid_type?
				@type == self.class::TYPE
			end
			
			def <=> other
				to_ary <=> other.to_ary
			end
			
			def to_ary
				[@length, @type, @flags, @stream_id, @payload]
			end
			
			# The generic frame header uses the following binary representation:
			#
			# +-----------------------------------------------+
			# |                 Length (24)                   |
			# +---------------+---------------+---------------+
			# |   Type (8)    |   Flags (8)   |
			# +-+-------------+---------------+-------------------------------+
			# |R|                 Stream Identifier (31)                      |
			# +=+=============================================================+
			# |                   Frame Payload (0...)                      ...
			# +---------------------------------------------------------------+
			
			attr_accessor :length
			attr_accessor :type
			attr_accessor :flags
			attr_accessor :stream_id
			attr_accessor :payload
			
			def unpack
				@payload
			end
			
			def pack(payload, maximum_size: nil)
				@payload = payload
				@length = payload.bytesize
				
				if maximum_size and @length > maximum_size
					raise ProtocolError, "Frame length #{@length} bigger than maximum allowed: #{maximum_size}"
				end
			end
			
			def set_flags(mask)
				@flags |= mask
			end
			
			def clear_flags(mask)
				@flags &= ~mask
			end
			
			def flag_set?(mask)
				@flags & mask != 0
			end
			
			# Check if frame is a connection frame: SETTINGS, PING, GOAWAY, and any
			# frame addressed to stream ID = 0.
			#
			# @return [Boolean]
			def connection?
				@stream_id.zero?
			end
			
			HEADER_FORMAT = 'CnCCN'.freeze
			STREAM_ID_MASK  = 0x7fffffff
			
			# Generates common 9-byte frame header.
			# - http://tools.ietf.org/html/draft-ietf-httpbis-http2-16#section-4.1
			#
			# @return [String]
			def header
				unless VALID_LENGTH.include? @length
					raise ProtocolError, "Invalid frame size: #{@length.inspect}"
				end
				
				unless VALID_STREAM_ID.include? @stream_id
					raise ProtocolError, "Invalid stream identifier: #{@stream_id.inspect}"
				end
				
				[
					# These are guaranteed correct due to the length check above.
					@length >> LENGTH_HISHIFT,
					@length & LENGTH_LOMASK,
					@type,
					@flags,
					@stream_id
				].pack(HEADER_FORMAT)
			end
			
			# Decodes common 9-byte header.
			#
			# @param buffer [String]
			def self.parse_header(buffer)
				length_hi, length_lo, type, flags, stream_id = buffer.unpack(HEADER_FORMAT)
				length = (length_hi << LENGTH_HISHIFT) | length_lo
				stream_id = stream_id & STREAM_ID_MASK
				
				# puts "parse_header: length=#{length} type=#{type} flags=#{flags} stream_id=#{stream_id}"
				
				return length, type, flags, stream_id
			end
			
			def read_header(stream)
				if buffer = stream.read(9) and buffer.bytesize == 9
					@length, @type, @flags, @stream_id = Frame.parse_header(buffer)
					# puts "read_header: #{@length} #{@type} #{@flags} #{@stream_id}"
				else
					raise EOFError, "Could not read frame header!"
				end
			end
			
			def read_payload(stream)
				if payload = stream.read(@length) and payload.bytesize == @length
					@payload = payload
				else
					raise EOFError, "Could not read frame payload!"
				end
			end
			
			def read(stream, maximum_frame_size = MAXIMUM_ALLOWED_FRAME_SIZE)
				read_header(stream) unless @length
				
				if @length > maximum_frame_size
					raise FrameSizeError, "#{self.class} (type=#{@type}) frame length #{@length} exceeds maximum frame size #{maximum_frame_size}!"
				end
				
				read_payload(stream)
			end
			
			def write_header(stream)
				stream.write self.header
			end
			
			def write_payload(stream)
				stream.write(@payload) if @payload
			end
			
			def write(stream)
				if @payload and @length != @payload.bytesize
					raise ProtocolError, "Invalid payload size: #{@length} != #{@payload.bytesize}"
				end
				
				self.write_header(stream)
				self.write_payload(stream)
			end
			
			def apply(connection)
				connection.receive_frame(self)
			end
			
			def inspect
				"\#<#{self.class} stream_id=#{@stream_id} flags=#{@flags} #{self.unpack}>"
			end
		end
	end
end
