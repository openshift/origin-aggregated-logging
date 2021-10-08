# Copyright, 2021, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../serialized/logger'

module Console
	module Output
		class Sensitive
			def initialize(output, **options)
				@output = output
			end
			
			REDACT = /
				  phone
				| email
				| full_?name
				| first_?name
				| last_?name
				
				| device_name
				| user_agent
				
				| zip
				| address
				| location
				| latitude
				| longitude
				
				| ip
				| gps
				
				| sex
				| gender
				
				| token
				| password
			/xi
			
			def redact?(text)
				text.match?(REDACT)
			end
			
			def redact_hash(arguments, filter)
				arguments.transform_values do |value|
					redact(value, filter)
				end
			end
			
			def redact_array(array, filter)
				array.map do |value|
					redact(value, filter)
				end
			end
			
			def redact(argument, filter)
				case argument
				when String
					if filter
						filter.call(argument)
					elsif redact?(argument)
						"[REDACTED]"
					else
						argument
					end
				when Array
					redact_array(argument, filter)
				when Hash
					redact_hash(argument, filter)
				else
					redact(argument.to_s, filter)
				end
			end
			
			class Filter
				def initialize(substitutions)
					@substitutions = substitutions
					@pattern = Regexp.union(substitutions.keys)
				end
				
				def call(text)
					text.gsub(@pattern, @substitutions)
				end
			end
			
			def call(subject = nil, *arguments, sensitive: true, **options, &block)
				if sensitive
					if sensitive.respond_to?(:call)
						filter = sensitive
					elsif sensitive.is_a?(Hash)
						filter = Filter.new(sensitive)
					end
					
					subject = redact(subject, filter)
					arguments = redact_array(arguments, filter)
				end
				
				@output.call(subject, *arguments, **options)
			end
		end
	end
end
