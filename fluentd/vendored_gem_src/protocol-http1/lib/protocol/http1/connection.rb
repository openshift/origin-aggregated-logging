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

require 'protocol/http/headers'

require_relative 'reason'
require_relative 'error'

require_relative 'body/chunked'
require_relative 'body/fixed'
require_relative 'body/remainder'
require 'protocol/http/body/head'

require 'protocol/http/methods'

module Protocol
	module HTTP1
		CONTENT_LENGTH = 'content-length'
		
		TRANSFER_ENCODING = 'transfer-encoding'
		CHUNKED = 'chunked'
		
		CONNECTION = 'connection'
		CLOSE = 'close'
		KEEP_ALIVE = 'keep-alive'
		
		HOST = 'host'
		UPGRADE = 'upgrade'
		
		# HTTP/1.x request line parser:
		TOKEN = /[!#$%&'*+-\.^_`|~0-9a-zA-Z]+/.freeze
		REQUEST_LINE = /\A(#{TOKEN}) ([^\s]+) (HTTP\/\d.\d)\z/.freeze
		
		# HTTP/1.x header parser:
		FIELD_NAME = TOKEN
		FIELD_VALUE = /[^\000-\037]*/.freeze
		HEADER = /\A(#{FIELD_NAME}):\s*(#{FIELD_VALUE})\s*\z/.freeze
		
		VALID_FIELD_NAME = /\A#{FIELD_NAME}\z/.freeze
		VALID_FIELD_VALUE = /\A#{FIELD_VALUE}\z/.freeze
		
		class Connection
			CRLF = "\r\n"
			HTTP10 = "HTTP/1.0"
			HTTP11 = "HTTP/1.1"
			
			def initialize(stream, persistent = true)
				@stream = stream
				
				@persistent = persistent
				
				@count = 0
			end
			
			attr :stream
			
			# Whether the connection is persistent.
			attr :persistent
			
			# The number of requests processed.
			attr :count
			
			def upgrade?(headers)
				if upgrade = headers[UPGRADE]
					return upgrade
				end
			end
			
			def persistent?(version, method, headers)
				if method == HTTP::Methods::CONNECT
					return false
				end
				
				if version == HTTP10
					if connection = headers[CONNECTION]
						return connection.keep_alive?
					else
						return false
					end
				else
					if connection = headers[CONNECTION]
						return !connection.close?
					else
						return true
					end
				end
			end
			
			# Write the appropriate header for connection persistence.
			def write_connection_header(version)
				if version == HTTP10
					@stream.write("connection: keep-alive\r\n") if @persistent
				else
					@stream.write("connection: close\r\n") unless @persistent
				end
			end
			
			def write_upgrade_header(upgrade)
				@stream.write("connection: upgrade\r\nupgrade: #{upgrade}\r\n")
			end
			
			# Effectively close the connection and return the underlying IO.
			# @return [IO] the underlying non-blocking IO.
			def hijack!
				@persistent = false
				stream = @stream
				
				@stream.flush
				@stream = nil
				
				return stream
			end
			
			# Close the connection and underlying stream.
			def close
				@stream&.close
			end
			
			def write_request(authority, method, path, version, headers)
				@stream.write("#{method} #{path} #{version}\r\n")
				@stream.write("host: #{authority}\r\n")
				
				write_headers(headers)
			end
			
			def write_response(version, status, headers, reason = Reason::DESCRIPTIONS[status])
				# Safari WebSockets break if no reason is given:
				@stream.write("#{version} #{status} #{reason}\r\n")
				
				write_headers(headers)
			end
			
			def write_headers(headers)
				headers.each do |name, value|
					# Convert it to a string:
					name = name.to_s
					value = value.to_s
					
					# Validate it:
					unless name.match?(VALID_FIELD_NAME)
						raise BadHeader, "Invalid header name: #{name.inspect}"
					end
					
					unless value.match?(VALID_FIELD_VALUE)
						raise BadHeader, "Invalid header value for #{name}: #{value.inspect}"
					end
					
					# Write it:
					@stream.write("#{name}: #{value}\r\n")
				end
			end
			
			def read_line?
				@stream.gets(CRLF, chomp: true)
			end
			
			def read_line
				read_line? or raise EOFError
			end
			
			def read_request
				return unless line = read_line?
				
				if match = line.match(REQUEST_LINE)
					_, method, path, version = *match
				else
					raise InvalidRequest, line.inspect
				end
				
				headers = read_headers
				
				@persistent = persistent?(version, method, headers)
				
				body = read_request_body(method, headers)
				
				@count += 1
				
				return headers.delete(HOST), method, path, version, headers, body
			end
			
			def read_response(method)
				version, status, reason = read_line.split(/\s+/, 3)
				
				status = Integer(status)
				
				headers = read_headers
				
				@persistent = persistent?(version, method, headers)
				
				body = read_response_body(method, status, headers)
				
				@count += 1
				
				return version, status, reason, headers, body
			end
			
			def read_headers
				fields = []
				
				while line = read_line
					# Empty line indicates end of headers:
					break if line.empty?
					
					if match = line.match(HEADER)
						fields << [match[1], match[2]]
					else
						raise BadHeader, "Could not parse header: #{line.dump}"
					end
				end
				
				return HTTP::Headers.new(fields)
			end
			
			# @param protocol [String] the protocol to upgrade to.
			def write_upgrade_body(protocol, body = nil)
				# Once we upgrade the connection, it can no longer handle other requests:
				@persistent = false
				
				write_upgrade_header(protocol)
				
				@stream.write("\r\n")
				@stream.flush # Don't remove me!
				
				if body
					body.each do |chunk|
						@stream.write(chunk)
						@stream.flush
					end
					
					@stream.close_write
				end
				
				return @stream
			end
			
			def write_tunnel_body(version, body = nil)
				@persistent = false
				
				write_connection_header(version)
				
				@stream.write("\r\n")
				@stream.flush # Don't remove me!
				
				if body
					body.each do |chunk|
						@stream.write(chunk)
						@stream.flush
					end
					
					@stream.close_write
				end
				
				return @stream
			end
			
			def write_empty_body(body)
				@stream.write("content-length: 0\r\n\r\n")
				@stream.flush
				
				body&.close
			end
			
			def write_fixed_length_body(body, length, head)
				@stream.write("content-length: #{length}\r\n\r\n")
				
				if head
					@stream.flush
					
					body.close
					
					return
				end
				
				@stream.flush unless body.ready?
				
				chunk_length = 0
				body.each do |chunk|
					chunk_length += chunk.bytesize
					
					if chunk_length > length
						raise Error, "Trying to write #{chunk_length} bytes, but content length was #{length} bytes!"
					end
					
					@stream.write(chunk)
					@stream.flush unless body.ready?
				end
				
				@stream.flush
				
				if chunk_length != length
					raise Error, "Wrote #{chunk_length} bytes, but content length was #{length} bytes!"
				end
			end
			
			def write_chunked_body(body, head, trailer = nil)
				@stream.write("transfer-encoding: chunked\r\n\r\n")
				
				if head
					@stream.flush
					
					body.close
					
					return
				end
				
				@stream.flush unless body.ready?
				
				body.each do |chunk|
					next if chunk.size == 0
					
					@stream.write("#{chunk.bytesize.to_s(16).upcase}\r\n")
					@stream.write(chunk)
					@stream.write(CRLF)
					
					@stream.flush unless body.ready?
				end
				
				if trailer
					@stream.write("0\r\n")
					write_headers(trailer)
					@stream.write("\r\n")
				else
					@stream.write("0\r\n\r\n")
				end
				
				@stream.flush
			end
			
			def write_body_and_close(body, head)
				# We can't be persistent because we don't know the data length:
				@persistent = false
				
				@stream.write("\r\n")
				@stream.flush unless body.ready?
				
				if head
					body.close
				else
					body.each do |chunk|
						@stream.write(chunk)
						
						@stream.flush unless body.ready?
					end
				end
				
				@stream.close_write
			end
			
			def write_body(version, body, head = false, trailer = nil)
				if body.nil?
					write_connection_header(version)
					write_empty_body(body)
				elsif length = body.length and trailer.nil?
					write_connection_header(version)
					write_fixed_length_body(body, length, head)
				elsif body.empty?
					# Even thought this code is the same as the first clause `body.nil?`, HEAD responses have an empty body but still carry a content length. `write_fixed_length_body` takes care of this appropriately.
					write_connection_header(version)
					write_empty_body(body)
				elsif version == HTTP11
					write_connection_header(version)
					# We specifically ensure that non-persistent connections do not use chunked response, so that hijacking works as expected.
					write_chunked_body(body, head, trailer)
				else
					@persistent = false
					write_connection_header(version)
					write_body_and_close(body, head)
				end
			end
			
			def read_chunked_body(headers)
				Body::Chunked.new(@stream, headers)
			end
			
			def read_fixed_body(length)
				Body::Fixed.new(@stream, length)
			end
			
			def read_remainder_body
				Body::Remainder.new(@stream)
			end
			
			def read_head_body(length)
				Protocol::HTTP::Body::Head.new(length)
			end
			
			def read_tunnel_body
				read_remainder_body
			end
			
			def read_upgrade_body(protocol)
				read_remainder_body
			end
			
			HEAD = "HEAD"
			CONNECT = "CONNECT"
			
			def read_response_body(method, status, headers)
				# RFC 7230 3.3.3
				# 1.  Any response to a HEAD request and any response with a 1xx
				# (Informational), 204 (No Content), or 304 (Not Modified) status
				# code is always terminated by the first empty line after the
				# header fields, regardless of the header fields present in the
				# message, and thus cannot contain a message body.
				if method == HTTP::Methods::HEAD
					if content_length = headers.delete(CONTENT_LENGTH)
						length = Integer(content_length)
						
						if length > 0
							return read_head_body(length)
						elsif length == 0
							return nil
						else
							raise BadRequest, "Invalid content length: #{content_length}"
						end
					else
						return nil
					end
				end
				
				if (status >= 100 and status < 200) or status == 204 or status == 304
					return nil
				end
				
				# 2.  Any 2xx (Successful) response to a CONNECT request implies that
				# the connection will become a tunnel immediately after the empty
				# line that concludes the header fields.  A client MUST ignore any
				# Content-Length or Transfer-Encoding header fields received in
				# such a message.
				if method == HTTP::Methods::CONNECT and status == 200
					return read_tunnel_body
				end
				
				return read_body(headers, true)
			end
			
			def read_request_body(method, headers)
				# 2.  Any 2xx (Successful) response to a CONNECT request implies that
				# the connection will become a tunnel immediately after the empty
				# line that concludes the header fields.  A client MUST ignore any
				# Content-Length or Transfer-Encoding header fields received in
				# such a message.
				if method == HTTP::Methods::CONNECT
					return read_tunnel_body
				end
				
				# 6.  If this is a request message and none of the above are true, then
				# the message body length is zero (no message body is present).
				return read_body(headers)
			end
			
			def read_body(headers, remainder = false)
				# 3.  If a Transfer-Encoding header field is present and the chunked
				# transfer coding (Section 4.1) is the final encoding, the message
				# body length is determined by reading and decoding the chunked
				# data until the transfer coding indicates the data is complete.
				if transfer_encoding = headers.delete(TRANSFER_ENCODING)
					# If a message is received with both a Transfer-Encoding and a
					# Content-Length header field, the Transfer-Encoding overrides the
					# Content-Length.  Such a message might indicate an attempt to
					# perform request smuggling (Section 9.5) or response splitting
					# (Section 9.4) and ought to be handled as an error.  A sender MUST
					# remove the received Content-Length field prior to forwarding such
					# a message downstream.
					if headers[CONTENT_LENGTH]
						raise BadRequest, "Message contains both transfer encoding and content length!"
					end
					
					if transfer_encoding.last == CHUNKED
						return read_chunked_body(headers)
					else
						# If a Transfer-Encoding header field is present in a response and
						# the chunked transfer coding is not the final encoding, the
						# message body length is determined by reading the connection until
						# it is closed by the server.  If a Transfer-Encoding header field
						# is present in a request and the chunked transfer coding is not
						# the final encoding, the message body length cannot be determined
						# reliably; the server MUST respond with the 400 (Bad Request)
						# status code and then close the connection.
						return read_remainder_body
					end
				end
				
				# 5.  If a valid Content-Length header field is present without
				# Transfer-Encoding, its decimal value defines the expected message
				# body length in octets.  If the sender closes the connection or
				# the recipient times out before the indicated number of octets are
				# received, the recipient MUST consider the message to be
				# incomplete and close the connection.
				if content_length = headers.delete(CONTENT_LENGTH)
					length = Integer(content_length)
					if length > 0
						return read_fixed_body(length)
					elsif length == 0
						return nil
					else
						raise BadRequest, "Invalid content length: #{content_length}"
					end
				end
				
				# http://tools.ietf.org/html/rfc2068#section-19.7.1.1
				if remainder
					# 7.  Otherwise, this is a response message without a declared message
					# body length, so the message body length is determined by the
					# number of octets received prior to the server closing the
					# connection.
					return read_remainder_body
				end
			end
		end
	end
end
