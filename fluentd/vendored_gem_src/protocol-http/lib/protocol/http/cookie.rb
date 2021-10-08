# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'url'

module Protocol
	module HTTP
		# Represents an individual cookie key-value pair.
		class Cookie
			def initialize(name, value, directives)
				@name = name
				@value = value
				@directives = directives
			end
			
			attr :name
			attr :value
			attr :directives
			
			def encoded_name
				URL.escape(@name)
			end
			
			def encoded_value
				URL.escape(@value)
			end
			
			def to_s
				buffer = String.new.b
				
				buffer << encoded_name << '=' << encoded_value
				
				if @directives
					@directives.collect do |key, value|
						buffer << ';'
						
						case value
						when String
							buffer << key << '=' << value
						when TrueClass
							buffer << key
						end
					end
				end
				
				return buffer
			end
			
			def self.parse(string)
				head, *directives = string.split(/\s*;\s*/)
				
				key, value = head.split('=')
				directives = self.parse_directives(directives)
				
				self.new(
					URL.unescape(key),
					URL.unescape(value),
					directives,
				)
			end
			
			def self.parse_directives(strings)
				strings.collect do |string|
					key, value = string.split('=', 2)
					[key, value || true]
				end.to_h
			end
		end
	end
end
